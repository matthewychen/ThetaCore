`include "cu_opcodes.vh"

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
        output reg ALU_err,
        output reg ALU_ready,

        //to CU
        output reg [31:0] ALU_out,
        output ALU_accept,
        output reg [1:0] ALU_result_counter
        );

        //for storage to mitigate data loss
        reg [4:0] Instruction_to_ALU;
        reg [31:0] reg_ALU_dat1;
        reg [31:0] reg_ALU_dat2;
        
        wire [31:0] AddSub_out;
        wire AddSub_overflow;  // Missing declaration
        wire [31:0] Comparator_out;
        wire Comparator_con_met; // Missing declaration
        wire [31:0] LogOp_out;
        wire [31:0] Shifter_out;

        assign ALU_accept = (ALU_result_counter == 2'b00);

        always@(posedge soc_clk) begin
            if (reset) begin
                // Reset logic
                ALU_result_counter <= 0;
                ALU_ready <= 0;
                ALU_out <= 32'b0;
                ALU_overflow <= 1'b0;
                ALU_zero <= 1'b0;
                ALU_con_met <= 1'b0;
                Instruction_to_ALU <= `ALUOP_NOP;
                reg_ALU_dat1 <= 32'b0;
                reg_ALU_dat2 <= 32'b0;
                ALU_err <= 1'b0;
            end
            else begin
                
                case(ALU_result_counter)
                    2'b00: begin
                        ALU_result_counter <= 01;
                        ALU_ready <= 1'b0;
                    end
                    2'b01: begin
                        // Idle state
                        ALU_ready <= 1'b0;
                        
                            reg_ALU_dat1 <= ALU_dat1;
                            reg_ALU_dat2 <= ALU_dat2;
                        
                        // Latch instruction
                            case(Instruction_from_CU)
                            //B
                            `CU_BEQ: Instruction_to_ALU <= `ALUOP_BEQ; //BEQ branch equal
                            `CU_BNE: Instruction_to_ALU <= `ALUOP_BNE; //BNE branch not equal
                            `CU_BLT: Instruction_to_ALU <= `ALUOP_BLT; //BLT branch less than
                            `CU_BGE: Instruction_to_ALU <= `ALUOP_BGE; //BGE branch greater than or equal
                            `CU_BLTU: Instruction_to_ALU <= `ALUOP_BLTU; //BLTU branch less than unsigned
                            `CU_BGEU: Instruction_to_ALU <= `ALUOP_BGEU; //BGEU branch greater than or equal unsigned

                            //I/R
                            `CU_ADD: Instruction_to_ALU <= `ALUOP_ADD; //ADD add 
                            `CU_ADDI: Instruction_to_ALU <= `ALUOP_ADD; //ADDI add 
                            `CU_SUB: Instruction_to_ALU <= `ALUOP_SUB; //SUB subtract 
                            `CU_SLL: Instruction_to_ALU <= `ALUOP_SLL; //SLL logical leftshift 
                            `CU_SLLI: Instruction_to_ALU <= `ALUOP_SLL; //SLLI logical leftshift
                            `CU_SLT: Instruction_to_ALU <= `ALUOP_SLT; //SLT set less than
                            `CU_SLTI: Instruction_to_ALU <= `ALUOP_SLT; //SLTI set less than
                            `CU_SLTU: Instruction_to_ALU <= `ALUOP_SLTU; //SLTU set less than unsigned
                            `CU_XOR: Instruction_to_ALU <= `ALUOP_XOR; //XOR xor 
                            `CU_XORI: Instruction_to_ALU <= `ALUOP_XOR; //XORI xor 
                            `CU_SRL: Instruction_to_ALU <= `ALUOP_SRL; //SRL logical rightshift 
                            `CU_SRLI: Instruction_to_ALU <= `ALUOP_SRL; //SRLI logical rightshift 
                            `CU_SRA: Instruction_to_ALU <= `ALUOP_SRA; //SRA arithmetic rightshift
                            `CU_SRAI: Instruction_to_ALU <= `ALUOP_SRA; //SRAI arithmetic rightshift 
                            `CU_OR: Instruction_to_ALU <= `ALUOP_OR; //OR or
                            `CU_ORI: Instruction_to_ALU <= `ALUOP_OR; //ORI or
                            `CU_AND: Instruction_to_ALU <= `ALUOP_AND; //AND and
                            `CU_ANDI: Instruction_to_ALU <= `ALUOP_AND; //ANDI and
                            default: Instruction_to_ALU <= `ALUOP_NOP; //no operation
                            endcase
                            ALU_result_counter <= 2'b10;
                    end
                    2'b10: begin 
                        ALU_result_counter <= 2'b11;
                        case(Instruction_to_ALU)
                            `ALUOP_ADD, `ALUOP_SUB: begin
                                ALU_out <= AddSub_out;
                                ALU_overflow <= AddSub_overflow;
                                ALU_zero <= ~|AddSub_out;
                                ALU_con_met <= 0;
                            end
                            `ALUOP_SLL, `ALUOP_SRL, `ALUOP_SRA: begin ALU_out <= Shifter_out;
                                ALU_overflow <= 0;
                                ALU_zero <= ~|Shifter_out;
                                ALU_con_met <= 0;
                            end
                            `ALUOP_XOR, `ALUOP_OR, `ALUOP_AND: begin ALU_out <= LogOp_out;
                                ALU_overflow <= 0;
                                ALU_zero <= ~|LogOp_out;
                                ALU_con_met <= 0;
                            end
                            `ALUOP_BEQ, `ALUOP_BNE, `ALUOP_BLT, `ALUOP_BGE,
                            `ALUOP_BLTU, `ALUOP_BGEU, `ALUOP_SLT, `ALUOP_SLTU: begin
                                ALU_out <= Comparator_out;
                                ALU_con_met <= Comparator_con_met;
                                ALU_overflow <= 0;
                                ALU_zero <= (Comparator_out==0);
                            end
                            default: begin ALU_out <= 32'b0;
                            ALU_overflow <= 0;
                            ALU_zero <= 1;
                            ALU_con_met <= 0;
                            end
                            
                        endcase
                        ALU_ready <= 1'b1;
                    end
                    2'b11: begin
                        ALU_ready <= 1'b0;
                        ALU_result_counter <= 2'b00;
                        end    
                endcase
            end 
        end


        

        //instantiations
        AddSub AS(
            .ALU_dat1(reg_ALU_dat1),
            .ALU_dat2(reg_ALU_dat2),
            .Instruction_to_ALU(Instruction_to_ALU),
            .AddSub_out(AddSub_out),
            .AddSub_overflow(AddSub_overflow)
        );

        Comparator C(
            .ALU_dat1(reg_ALU_dat1),
            .ALU_dat2(reg_ALU_dat2),
            .Instruction_to_ALU(Instruction_to_ALU),
            .Comparator_out(Comparator_out),
            .Comparator_con_met(Comparator_con_met)
        );

        LogOp LO(
            .ALU_dat1(reg_ALU_dat1),
            .ALU_dat2(reg_ALU_dat2),
            .Instruction_to_ALU(Instruction_to_ALU),
            .LogOp_out(LogOp_out)
        );

        Shifter S(
            .ALU_dat1(reg_ALU_dat1),
            .ALU_dat2(reg_ALU_dat2),
            .Instruction_to_ALU(Instruction_to_ALU),
            .Shifter_out(Shifter_out)
        );

    endmodule