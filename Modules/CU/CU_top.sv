`include "cu_opcodes.vh"

//==============================================================================
// Multi-cycle RV32I control unit.
//
// Five states, one state register. Each state sets a handful of mux selects;
// the instruction type sets the rest. That is the whole control unit -- see the
// two tables below.
//
// Multi-cycle rather than single-cycle because SRAM_sim is synchronous: it
// registers its read, so an address presented this cycle yields data next
// cycle. The Berkeley single-cycle datapath assumes asynchronous IMEM/DMEM,
// which no real SRAM (and no FPGA block RAM) provides.
//==============================================================================

module CU_top(
    input soc_clk,
    input reset,

    // observation only, for the testbench
    output [31:0] dbg_PC,
    output [31:0] dbg_IR,
    output [2:0]  dbg_state,
    output        dbg_retire,
    output        halted
);

//------------------------------------------------------------------------------
// Per-stage latency.
//
// IDU_top and ALU_top each run a four-phase internal counter, so the FSM waits
// them out. Both are purely combinational underneath -- B10 collapses those
// counters and these two constants become 1, taking the core from roughly
// 13 CPI to roughly 5. Parameterising it makes that a two-line change rather
// than an FSM rewrite.
//------------------------------------------------------------------------------
localparam [2:0] IDU_LATENCY = 3'd4;
localparam [2:0] ALU_LATENCY = 3'd4;

localparam [2:0] S_IF  = 3'd0,
                 S_ID  = 3'd1,
                 S_EX  = 3'd2,
                 S_MEM = 3'd3,
                 S_WB  = 3'd4,
                 S_HALT= 3'd5;

reg [2:0]  state;
reg [2:0]  cyc;
reg [31:0] Cu_IR;

// ID/EX boundary registers.
// IDU_reset is held high outside S_ID, and the IDU's reset clause zeroes every
// output -- so the decode has to be captured before we leave the state that
// produced it. In a pipelined build these same registers become the ID/EX
// pipeline register; here they exist for a less glamorous reason.
reg [5:0]  cu_op_r;
reg [31:0] imm_r;
reg [4:0]  rd_r, rs1_r, rs2_r, shamt_r;
reg [31:0] pc_increment_r;
reg        invalid_r;

// EX/MEM boundary. Same reasoning: EX_reset clears ALU_out.
reg [31:0] alu_result_r;
reg        con_met_r;
reg [31:0] load_data_r;

//------------------------------------------------------------------------------
// Sub-module wiring
//------------------------------------------------------------------------------
wire [5:0]  Instruction_to_CU;
wire [31:0] imm, pc_increment;
wire [4:0]  rd, rs1, rs2, shamt;
wire        invalid_instruction;

wire [31:0] PC, pc_plus_4;
wire [31:0] rs1_data, rs2_data;
wire [31:0] ALU_out;
wire        ALU_ready, ALU_overflow, ALU_zero, ALU_con_met, ALU_err, ALU_accept;
wire [1:0]  ALU_stage;
wire [31:0] MMU_dat_out;
wire        MMU_ready;

//------------------------------------------------------------------------------
// Instruction classification. Ranges are contiguous by construction -- see the
// grouping in cu_opcodes.vh.
//------------------------------------------------------------------------------
wire is_load   = (cu_op_r >= `CU_LB)  && (cu_op_r <= `CU_LHU);
wire is_store  = (cu_op_r >= `CU_SB)  && (cu_op_r <= `CU_SW);
wire is_branch = (cu_op_r >= `CU_BEQ) && (cu_op_r <= `CU_BGEU);
wire is_rtype  = (cu_op_r >= `CU_ADD) && (cu_op_r <= `CU_AND);
wire is_jal    = (cu_op_r == `CU_JAL);
wire is_jalr   = (cu_op_r == `CU_JALR);
wire is_lui    = (cu_op_r == `CU_LUI);
wire is_auipc  = (cu_op_r == `CU_AUIPC);
wire is_shifti = (cu_op_r == `CU_SLLI) || (cu_op_r == `CU_SRLI) ||
                 (cu_op_r == `CU_SRAI);
wire is_fence  = (cu_op_r == `CU_FENCE) || (cu_op_r == `CU_FENCE_I);
wire is_system = (cu_op_r == `CU_ECALL) || (cu_op_r == `CU_EBREAK);
wire needs_mem = is_load || is_store;

//------------------------------------------------------------------------------
// Control table: mux selects by instruction type.
//------------------------------------------------------------------------------
wire [1:0] ASel  = is_auipc ? `ASEL_PC
                 : is_lui   ? `ASEL_ZERO
                 :            `ASEL_RS1;

wire [1:0] BSel  = is_shifti               ? `BSEL_SHAMT
                 : (is_rtype || is_branch) ? `BSEL_RS2
                 :                           `BSEL_IMM;

wire [1:0] WBSel = is_load             ? `WBSEL_MEM
                 : (is_jal || is_jalr) ? `WBSEL_PC4
                 :                       `WBSEL_ALU;

// Stores, branches, fences and system calls produce no architectural result.
// The register file independently refuses writes to x0.
wire wb_enable = !(is_store || is_branch || is_fence || is_system);

wire [1:0] PCSel = is_jalr                  ? `PCSEL_JALR
                 : (is_branch && con_met_r) ? `PCSEL_BRANCH
                 :                            `PCSEL_SEQ;

wire [1:0] mem_width =
    (cu_op_r == `CU_LB || cu_op_r == `CU_LBU || cu_op_r == `CU_SB) ? `MEMW_BYTE :
    (cu_op_r == `CU_LH || cu_op_r == `CU_LHU || cu_op_r == `CU_SH) ? `MEMW_HALF :
                                                                     `MEMW_WORD;

wire mem_signed = (cu_op_r == `CU_LB) || (cu_op_r == `CU_LH);

//------------------------------------------------------------------------------
// The five muxes.
//------------------------------------------------------------------------------
wire [31:0] alu_a = (ASel == `ASEL_PC)    ? PC
                  : (ASel == `ASEL_ZERO)  ? 32'b0
                  :                         rs1_data;

wire [31:0] alu_b = (BSel == `BSEL_IMM)   ? imm_r
                  : (BSel == `BSEL_SHAMT) ? {27'b0, shamt_r}
                  :                         rs2_data;

wire [31:0] wb_data = (WBSel == `WBSEL_MEM) ? load_data_r
                    : (WBSel == `WBSEL_PC4) ? pc_plus_4
                    :                         alu_result_r;

// Memory address mux: PC during fetch, the computed effective address in MEM.
wire [31:0] mem_addr = (state == S_IF) ? PC          : alu_result_r;
wire [1:0]  mem_w    = (state == S_IF) ? `MEMW_WORD  : mem_width;
wire        mem_sgn  = (state == S_IF) ? 1'b0        : mem_signed;
wire        mem_rw   = (state == S_IF) ? `MEMRW_READ
                                       : (is_store ? `MEMRW_WRITE : `MEMRW_READ);

// retrieve may stay asserted for the whole state: the MMU only samples it in
// its own idle state, and we leave S_IF/S_MEM on the same edge it returns
// there, so no second access can start.
wire mem_req = (state == S_IF) || (state == S_MEM);

//------------------------------------------------------------------------------
// State-driven enables.
//------------------------------------------------------------------------------
wire IDU_reset  = reset || (state != S_ID);
wire EX_reset   = reset || (state != S_EX);
wire RegWEn     = (state == S_WB) && wb_enable;

// Hold the PC on a halt so it points AT the instruction that stopped the
// machine rather than one past it -- the same reason a trap handler wants
// mepc to name the faulting instruction.
wire PCWrite    = (state == S_WB) && !(is_system || invalid_r);

assign dbg_PC     = PC;
assign dbg_IR     = Cu_IR;
assign dbg_state  = state;
assign dbg_retire = (state == S_WB);
assign halted     = (state == S_HALT);

//------------------------------------------------------------------------------
// Sequencer
//------------------------------------------------------------------------------
always @(posedge soc_clk or posedge reset) begin
    if (reset) begin
        state <= S_IF; cyc <= 3'd0; Cu_IR <= 32'b0;
        cu_op_r <= 6'b0; imm_r <= 32'b0; rd_r <= 5'b0; rs1_r <= 5'b0;
        rs2_r <= 5'b0; shamt_r <= 5'b0; pc_increment_r <= 32'd4;
        invalid_r <= 1'b0;
        alu_result_r <= 32'b0; con_met_r <= 1'b0; load_data_r <= 32'b0;
    end else begin
        case (state)
            S_IF: if (MMU_ready) begin
                Cu_IR <= MMU_dat_out;
                cyc   <= 3'd0;
                state <= S_ID;
            end

            S_ID: if (cyc == IDU_LATENCY - 1) begin
                // Capture the decode before IDU_reset reasserts and zeroes it.
                cu_op_r        <= Instruction_to_CU;
                imm_r          <= imm;
                rd_r           <= rd;
                rs1_r          <= rs1;
                rs2_r          <= rs2;
                shamt_r        <= shamt;
                pc_increment_r <= pc_increment;
                invalid_r      <= invalid_instruction;
                cyc            <= 3'd0;
                state          <= S_EX;
            end else cyc <= cyc + 3'd1;

            S_EX: if (cyc == ALU_LATENCY - 1) begin
                // Same again: EX_reset clears ALU_out on the way out.
                alu_result_r <= ALU_out;
                con_met_r    <= ALU_con_met;
                cyc          <= 3'd0;
                state        <= needs_mem ? S_MEM : S_WB;
            end else cyc <= cyc + 3'd1;

            S_MEM: if (MMU_ready) begin
                load_data_r <= MMU_dat_out;   // ignored by stores
                cyc         <= 3'd0;
                state       <= S_WB;
            end

            S_WB: begin
                cyc <= 3'd0;
                if (is_system || invalid_r) begin
                    // ECALL/EBREAK are program termination per the README.
                    // invalid_r here means the IDU could not classify the word.
                    if (invalid_r)
                        $display("[CU] halt: invalid instruction, PC=%0d IR=%08x",
                                 PC, Cu_IR);
                    else
                        $display("[CU] halt: ecall/ebreak at PC=%0d", PC);
                    state <= S_HALT;
                end else state <= S_IF;
            end

            S_HALT: state <= S_HALT;

            default: state <= S_IF;
        endcase
    end
end

//------------------------------------------------------------------------------
// Datapath instances
//------------------------------------------------------------------------------
CU_ID instruction_decoder(
    .soc_clk            (soc_clk),
    .ID_reset           (IDU_reset),
    .Cu_IR              (Cu_IR),
    .Instruction_to_CU  (Instruction_to_CU),
    .imm                (imm),
    .rd                 (rd),
    .rs1                (rs1),
    .rs2                (rs2),
    .shamt              (shamt),
    .pc_increment       (pc_increment),
    .invalid_instruction(invalid_instruction)
);

regfile registers(
    .soc_clk (soc_clk),
    .reset   (reset),
    .rs1_addr(rs1_r),
    .rs2_addr(rs2_r),
    .rs1_data(rs1_data),
    .rs2_data(rs2_data),
    .RegWEn  (RegWEn),
    .rd_addr (rd_r),
    .rd_data (wb_data)
);

pc_unit program_counter(
    .soc_clk     (soc_clk),
    .reset       (reset),
    .PCWrite     (PCWrite),
    .PCSel       (PCSel),
    .pc_increment(pc_increment_r),
    .imm         (imm_r),
    .alu_out     (alu_result_r),
    .PC          (PC),
    .pc_plus_4   (pc_plus_4)
);

CU_EX execute(
    .soc_clk           (soc_clk),
    .EX_reset          (EX_reset),
    .rs1_data          (alu_a),
    .rs2_data          (alu_b),
    .imm_data          (imm_r),          // unused downstream, ALU takes dat1/dat2
    .Instruction_to_ALU(cu_op_r),
    .result_data       (ALU_out),
    .result_ready      (ALU_ready),
    .overflow_flag     (ALU_overflow),
    .zero_flag         (ALU_zero),
    .condition_met_flag(ALU_con_met),
    .error_flag        (ALU_err),
    .EX_accept         (ALU_accept),
    .stage_counter     (ALU_stage)
);

MMU memory(
    .soc_clk      (soc_clk),
    .reset        (reset),
    .CU_address   (mem_addr),
    .CU_width     (mem_w),
    .CU_signed    (mem_sgn),
    .CU_dat_in    (rs2_data),   // store data
    .read_or_write(mem_rw),
    .retrieve     (mem_req),
    .MMU_ready    (MMU_ready),
    .MMU_dat_out  (MMU_dat_out)
);

//------------------------------------------------------------------------------
// Register ABI reference
// x0  zero  | x1  ra   | x2  sp   | x3  gp   | x4  tp   | x5-x7   t0-t2
// x8  s0/fp | x9  s1   | x10-x17  a0-a7      | x18-x27  s2-s11
// x28-x31   t3-t6
//------------------------------------------------------------------------------

endmodule
