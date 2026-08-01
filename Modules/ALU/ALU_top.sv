`include "cu_opcodes.vh"

//==============================================================================
// ALU.
//
// B10: collapsed from a four-phase sequencer to a single registered cycle.
// The old phase 00 only advanced a counter, phase 01 latched operands and
// translated the opcode, phase 10 computed, phase 11 cleared a flag. Every
// sub-block (AddSub, Comparator, LogOp, Shifter) is combinational, so three of
// those four phases were pure ceremony.
//
// The ALU_accept / ALU_ready handshake is preserved exactly, which is why the
// testbench needed no changes: it waits on the handshake rather than counting
// cycles.
//==============================================================================

    module ALU_top(
        //templated
        input soc_clk,
        input reset,
        //databusses
        input [31:0] ALU_dat1,
        input [31:0] ALU_dat2,
        input [5:0] Instruction_from_CU, //from IDU -> CU reg -> ALU

        //flags
        output reg ALU_overflow,
        output reg ALU_con_met, //branching and SLTI flag
        output reg ALU_zero,
        output reg ALU_ready,

        //to CU
        output reg [31:0] ALU_out,
        output ALU_accept,
        output reg [1:0] ALU_result_counter
        );

        wire [31:0] AddSub_out;
        wire        AddSub_overflow;
        wire [31:0] Comparator_out;
        wire        Comparator_con_met;
        wire [31:0] LogOp_out;
        wire [31:0] Shifter_out;

        //----------------------------------------------------------------------
        // CU opcode -> ALU operation. A lookup, not a computation.
        //----------------------------------------------------------------------
        reg [4:0] Instruction_to_ALU;

        always @(*) begin
            case(Instruction_from_CU)
            //B
            `CU_BEQ:   Instruction_to_ALU = `ALUOP_BEQ;
            `CU_BNE:   Instruction_to_ALU = `ALUOP_BNE;
            `CU_BLT:   Instruction_to_ALU = `ALUOP_BLT;
            `CU_BGE:   Instruction_to_ALU = `ALUOP_BGE;
            `CU_BLTU:  Instruction_to_ALU = `ALUOP_BLTU;
            `CU_BGEU:  Instruction_to_ALU = `ALUOP_BGEU;

            //I/R
            `CU_ADD:   Instruction_to_ALU = `ALUOP_ADD;
            `CU_ADDI:  Instruction_to_ALU = `ALUOP_ADD;
            `CU_SUB:   Instruction_to_ALU = `ALUOP_SUB;
            `CU_SLL:   Instruction_to_ALU = `ALUOP_SLL;
            `CU_SLLI:  Instruction_to_ALU = `ALUOP_SLL;
            `CU_SLT:   Instruction_to_ALU = `ALUOP_SLT;
            `CU_SLTI:  Instruction_to_ALU = `ALUOP_SLT;
            `CU_SLTU:  Instruction_to_ALU = `ALUOP_SLTU;
            `CU_SLTIU: Instruction_to_ALU = `ALUOP_SLTU;
            `CU_XOR:   Instruction_to_ALU = `ALUOP_XOR;
            `CU_XORI:  Instruction_to_ALU = `ALUOP_XOR;
            `CU_SRL:   Instruction_to_ALU = `ALUOP_SRL;
            `CU_SRLI:  Instruction_to_ALU = `ALUOP_SRL;
            `CU_SRA:   Instruction_to_ALU = `ALUOP_SRA;
            `CU_SRAI:  Instruction_to_ALU = `ALUOP_SRA;
            `CU_OR:    Instruction_to_ALU = `ALUOP_OR;
            `CU_ORI:   Instruction_to_ALU = `ALUOP_OR;
            `CU_AND:   Instruction_to_ALU = `ALUOP_AND;
            `CU_ANDI:  Instruction_to_ALU = `ALUOP_AND;

            //effective address calculation, rs1 + imm
            `CU_LB, `CU_LH, `CU_LW,
            `CU_LBU, `CU_LHU:        Instruction_to_ALU = `ALUOP_ADD;
            `CU_SB, `CU_SH, `CU_SW:  Instruction_to_ALU = `ALUOP_ADD;

            //LUI (a mux supplies zero), AUIPC (a mux supplies PC), JALR
            `CU_LUI, `CU_AUIPC,
            `CU_JALR:  Instruction_to_ALU = `ALUOP_ADD;

            default:   Instruction_to_ALU = `ALUOP_NOP;
            endcase
        end

        //----------------------------------------------------------------------
        // Result selection, combinational.
        //----------------------------------------------------------------------
        reg [31:0] result_c;
        reg        ovf_c, zero_c, con_c;

        always @(*) begin
            case(Instruction_to_ALU)
                `ALUOP_ADD, `ALUOP_SUB: begin
                    result_c = AddSub_out;
                    ovf_c    = AddSub_overflow;
                    zero_c   = ~|AddSub_out;
                    con_c    = 1'b0;
                end
                `ALUOP_SLL, `ALUOP_SRL, `ALUOP_SRA: begin
                    result_c = Shifter_out;
                    ovf_c    = 1'b0;
                    zero_c   = ~|Shifter_out;
                    con_c    = 1'b0;
                end
                `ALUOP_XOR, `ALUOP_OR, `ALUOP_AND: begin
                    result_c = LogOp_out;
                    ovf_c    = 1'b0;
                    zero_c   = ~|LogOp_out;
                    con_c    = 1'b0;
                end
                `ALUOP_BEQ, `ALUOP_BNE, `ALUOP_BLT, `ALUOP_BGE,
                `ALUOP_BLTU, `ALUOP_BGEU, `ALUOP_SLT, `ALUOP_SLTU: begin
                    result_c = Comparator_out;
                    ovf_c    = 1'b0;
                    zero_c   = (Comparator_out == 0);
                    con_c    = Comparator_con_met;
                end
                default: begin
                    result_c = 32'b0;
                    ovf_c    = 1'b0;
                    zero_c   = 1'b1;
                    con_c    = 1'b0;
                end
            endcase
        end

        //----------------------------------------------------------------------
        // One registered cycle, handshake preserved.
        //----------------------------------------------------------------------
        reg busy;
        assign ALU_accept = !busy;

        always@(posedge soc_clk) begin
            if (reset) begin
                busy         <= 1'b0;
                ALU_ready    <= 1'b0;
                ALU_out      <= 32'b0;
                ALU_overflow <= 1'b0;
                ALU_zero     <= 1'b0;
                ALU_con_met  <= 1'b0;
                ALU_result_counter <= 2'b00;
            end
            else if (!busy) begin
                ALU_out      <= result_c;
                ALU_overflow <= ovf_c;
                ALU_zero     <= zero_c;
                ALU_con_met  <= con_c;
                ALU_ready    <= 1'b1;
                busy         <= 1'b1;
                ALU_result_counter <= 2'b01;
            end
            else begin
                ALU_ready    <= 1'b0;
                busy         <= 1'b0;
                ALU_result_counter <= 2'b00;
            end
        end

        //instantiations. Fed directly from the input busses now -- the old
        //reg_ALU_dat1/reg_ALU_dat2 shadow copies existed only to hold operands
        //stable across the discarded phases.
        AddSub AS(
            .ALU_dat1(ALU_dat1),
            .ALU_dat2(ALU_dat2),
            .Instruction_to_ALU(Instruction_to_ALU),
            .AddSub_out(AddSub_out),
            .AddSub_overflow(AddSub_overflow)
        );

        Comparator C(
            .ALU_dat1(ALU_dat1),
            .ALU_dat2(ALU_dat2),
            .Instruction_to_ALU(Instruction_to_ALU),
            .Comparator_out(Comparator_out),
            .Comparator_con_met(Comparator_con_met)
        );

        LogOp LO(
            .ALU_dat1(ALU_dat1),
            .ALU_dat2(ALU_dat2),
            .Instruction_to_ALU(Instruction_to_ALU),
            .LogOp_out(LogOp_out)
        );

        Shifter S(
            .ALU_dat1(ALU_dat1),
            .ALU_dat2(ALU_dat2),
            .Instruction_to_ALU(Instruction_to_ALU),
            .Shifter_out(Shifter_out)
        );

    endmodule
