`include "cu_opcodes.vh"
`timescale 1ns/1ps

module tb_alu;

    //----------------------------------------------------------------
    // Signal Declarations
    //----------------------------------------------------------------
    reg soc_clk;
    reg reset;
    reg dat_ready;
    reg [31:0] ALU_dat1;
    reg [31:0] ALU_dat2;
    reg [5:0] Instruction_from_CU;

    wire ALU_overflow;
    wire ALU_con_met;
    wire ALU_zero;
    wire ALU_ready;
    wire [31:0] ALU_out;

    //----------------------------------------------------------------
    // DUT Instantiation
    //----------------------------------------------------------------
wire [1:0] stage_counter;
wire EX_accept;

CU_EX dut (
    .soc_clk(soc_clk),
    .EX_reset(reset),

    .rs1_data(ALU_dat1),
    .rs2_data(ALU_dat2),
    .imm_data(32'b0),              // unused for now
    .Instruction_to_ALU(Instruction_from_CU),

    .result_data(ALU_out),
    .result_ready(ALU_ready),
    .overflow_flag(ALU_overflow),
    .zero_flag(ALU_zero),
    .condition_met_flag(ALU_con_met),
    .EX_accept(EX_accept),
    .stage_counter(stage_counter)
);

    //----------------------------------------------------------------
    // Clock Generation
    //----------------------------------------------------------------
    initial begin
        soc_clk = 0;
        forever #5 soc_clk = ~soc_clk;
    end

    //----------------------------------------------------------------
    // Waveform Dumping
    //----------------------------------------------------------------
    initial begin
        $dumpfile("alu_wave.vcd");
        $dumpvars(0, tb_alu);
    end

    //----------------------------------------------------------------
    // Test Sequence
    //----------------------------------------------------------------
    initial begin
        $display("Starting ALU Testbench...");

        // 1. Reset the DUT
        reset = 1;
        dat_ready = 0;
        ALU_dat1 = 0;
        ALU_dat2 = 0;
        Instruction_from_CU = 0;
        @(posedge soc_clk);
        @(posedge soc_clk);
        reset = 0;
        @(posedge soc_clk);
        $display("Reset complete.");

        // Format: testsequence(Name, In1, In2, OpCode, ExpOut, ExpZero, ExpOvf, ExpConMet);

        // --- Arithmetic ---
        // ADD: 10 + 5 = 15
        testsequence("ADD (10+5)",   32'd10, 32'd5, `CU_ADD, 32'd15, 0, 0, 0);
        
        // SUB: 10 - 5 = 5
        testsequence("SUB (10-5)",   32'd10, 32'd5, `CU_SUB, 32'd5,  0, 0, 0);
        
        // SUB: 5 - 10 = -5 (0xFFFFFFFB)
        testsequence("SUB (5-10)",   32'd5, 32'd10, `CU_SUB, 32'hFFFF_FFFB, 0, 0, 0);

        // --- Shifts ---
        // SLL: 1 << 2 = 4
        testsequence("SLL (1<<2)",   32'd1, 32'd2, `CU_SLL, 32'd4, 0, 0, 0);
        
        // SRL: 8 >> 2 = 2
        testsequence("SRL (8>>2)",   32'd8, 32'd2, `CU_SRL, 32'd2, 0, 0, 0);
        
        // SRA: -8 >>> 2 = -2 (0xFFFFFFFE)
        testsequence("SRA (-8>>>2)", 32'hFFFF_FFF8, 32'd2, `CU_SRA, 32'hFFFF_FFFE, 0, 0, 0);

        // --- Logical ---
        // XOR: F0 ^ 0F = FF
        testsequence("XOR (F0^0F)",  32'hF0, 32'h0F, `CU_XOR, 32'hFF, 0, 0, 0);
        
        // OR: F0 | 0F = FF
        testsequence("OR  (F0|0F)",  32'hF0, 32'h0F, `CU_OR, 32'hFF, 0, 0, 0);
        
        // AND: F0 & 0F = 00
        testsequence("AND (F0&0F)",  32'hF0, 32'h0F, `CU_AND, 32'h00, 1, 0, 0);

        // --- Set Less Than ---
        // SLT (Signed): -1 < 10 -> True (1)
        testsequence("SLT (-1 < 10)", 32'hFFFF_FFFF, 32'd10, `CU_SLT, 32'd1, 0, 0, 0);
        
        // SLTU (Unsigned): -1 (MaxUint) < 10 -> False (0)
        testsequence("SLTU (-1 < 10)", 32'hFFFF_FFFF, 32'd10, `CU_SLTU, 32'd0, 1, 0, 0);

        // --- Branches ---
        // BEQ: 5 == 5 -> Met
        testsequence("BEQ (5==5)",    32'd5, 32'd5, `CU_BEQ, 32'd0, 1, 0, 1);
        
        // BNE: 5 != 4 -> Met
        testsequence("BNE (5!=4)",    32'd5, 32'd4, `CU_BNE, 32'd0, 1, 0, 1);
        
        // BLT: -5 < 5 -> Met
        testsequence("BLT (-5<5)",   32'hFFFF_FFFB, 32'd5, `CU_BLT, 32'd0, 1, 0, 1);
        
        // BGE: 5 >= -5 -> Met
        testsequence("BGE (5>=-5)",   32'd5, 32'hFFFF_FFFB, `CU_BGE, 32'd0, 1, 0, 1);
        
        // BLTU: 10 < 20 -> Met
        testsequence("BLTU (10<20)",  32'd10, 32'd20, `CU_BLTU, 32'd0, 1, 0, 1);
        
        // BGEU: 20 >= 10 -> Met
        testsequence("BGEU (20>=10)", 32'd20, 32'd10, `CU_BGEU, 32'd0, 1, 0, 1);

        // --- Effective address calculation (B4) ---
        // Every one of these previously fell through to ALUOP_NOP and
        // returned 0, so the ALU could not produce a memory address.
        testsequence("LW addr (0x100+0x20)", 32'h100, 32'h20, `CU_LW,  32'h120, 0, 0, 0);
        testsequence("SW addr (0x200+4)",    32'h200, 32'd4,  `CU_SW,  32'h204, 0, 0, 0);
        testsequence("LB addr (0x40-4)",     32'h40,  32'hFFFF_FFFC, `CU_LB, 32'h3C, 0, 0, 0);
        testsequence("SB addr (0x10+1)",     32'h10,  32'd1,  `CU_SB,  32'h11, 0, 0, 0);

        // --- Jump / upper immediate targets (B4) ---
        testsequence("JALR (0x80+0x10)",     32'h80,   32'h10, `CU_JALR,  32'h90,   0, 0, 0);
        testsequence("AUIPC (0x1000+0x24)",  32'h1000, 32'h24, `CU_AUIPC, 32'h1024, 0, 0, 0);

        // --- SLTIU was absent from the ALU decode table entirely ---
        testsequence("SLTIU (5 < 10)",       32'd5, 32'd10, `CU_SLTIU, 32'd1, 0, 0, 0);

        $display("Testbench finished.");
        $finish;
    end

    //----------------------------------------------------------------
    // Test Task
    //----------------------------------------------------------------
    // Note: Using reg [255:0] for name to be compatible with standard Verilog
task testsequence;
    input [8*32-1:0] name; 
    input [31:0] in1;
    input [31:0] in2;
    input [5:0] instr;
    input [31:0] exp_out;
    input exp_zero;
    input exp_ovf;
    input exp_con;
begin
    // --------------------------------------------------
    // 1. Wait until ALU explicitly accepts a new op
    //
    // Every wait settles with #1 before sampling. Reading a signal in the
    // active region immediately after @(posedge) returns its PRE-edge value,
    // because non-blocking updates have not been applied yet -- so the
    // handshake would be observed one cycle stale. The old four-phase ALU had
    // enough slack to hide this; a tighter one does not.
    // --------------------------------------------------
    #1;
    while (!EX_accept) begin
        @(posedge soc_clk); #1;
    end

    // --------------------------------------------------
    // 2. Drive inputs while accept is HIGH
    //    (must be stable before capture edge)
    // --------------------------------------------------
    ALU_dat1 = in1;
    ALU_dat2 = in2;
    Instruction_from_CU = instr;

    // --------------------------------------------------
    // 3. Capture happens on THIS posedge
    // --------------------------------------------------
    @(posedge soc_clk); #1;

    // --------------------------------------------------
    // 4. Wait for result valid
    // --------------------------------------------------
    while (!ALU_ready) begin
        @(posedge soc_clk); #1;
    end

    // --------------------------------------------------
    // 5. Check outputs
    // --------------------------------------------------
    if (ALU_out !== exp_out ||
        ALU_zero !== exp_zero ||
        ALU_overflow !== exp_ovf ||
        ALU_con_met !== exp_con) begin

        $display("ERROR: %0s FAILED", name);
        $display("  Inputs: A=%h, B=%h, Instr=%d", in1, in2, instr);
        $display("  Expected: Out=%h, zeroflag=%b, overflow=%b, condition=%b",
                 exp_out, exp_zero, exp_ovf, exp_con);
        $display("  Actual:   Out=%h, zeroflag=%b, overflow=%b, condition=%b",
                 ALU_out, ALU_zero, ALU_overflow, ALU_con_met);
    end else begin
        $display("PASS: %0s", name);
    end

    // --------------------------------------------------
    // 6. Cooldown (optional but clean)
    // --------------------------------------------------
    @(posedge soc_clk);
end
endtask




endmodule