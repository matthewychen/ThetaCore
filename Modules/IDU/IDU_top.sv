`include "cu_opcodes.vh"

module IDU_top(
    //templated
    input soc_clk,
    input IDU_reset, //flushing
    input [31:0] instruction,

    output reg [5:0] Instruction_to_CU   , //CU instruction select. refer to cu_code_ref.md to decode.

    //databusses
    output reg [31:0] imm,
    output reg [4:0] rd, //CU register sel
    output reg [4:0] rs1,
    output reg [4:0] rs2,
    output reg [4:0] shamt,
    output reg [31:0] pc_increment,

    //flags
    //00 -> no override
    //01 -> override rs1
    //10 -> override rs2
    output reg invalid_instruction
);

reg [1:0] IDU_result_counter;
reg [3:0] decryptedOPtype;
//0  -> LUI U
//1  -> AUIPC U
//2  ->  JAL J
//3  -> JALR J
//4  -> B
//5  -> S
//6  -> IG1 (load)
//7  -> IG2 (calc)
//8  -> R
//9  -> fence/fence.i
//10  -> ecall/ebreak
//11 -> invalid
//12 -> initial

always@(posedge soc_clk or posedge IDU_reset) begin
    if(IDU_reset) begin
        decryptedOPtype <= `OPT_INITIAL;
        imm <= 32'bz;
        rd <= 5'bz;
        rs1 <= 5'bz;
        rs2 <= 5'bz;
        shamt <= 5'bz;
        pc_increment <= 4;
        Instruction_to_CU <= `CU_LUI;
        invalid_instruction <= 0;
        IDU_result_counter <= 0;
    end
    else begin
        IDU_result_counter <= IDU_result_counter + 1;
        case(IDU_result_counter)
            0: //recieve data
                begin end

            1: //decode broad type
                case(instruction[6:0]) //optype classification
                    7'b0110111: decryptedOPtype <= `OPT_LUI;
                    7'b0010111: decryptedOPtype <= `OPT_AUIPC;
                    7'b1101111: decryptedOPtype <= `OPT_JAL;
                    7'b1100111: decryptedOPtype <= `OPT_JALR;
                    7'b1100011: decryptedOPtype <= `OPT_B;
                    7'b0100011: decryptedOPtype <= `OPT_S;
                    7'b0000011: decryptedOPtype <= `OPT_LOAD;
                    7'b0010011: decryptedOPtype <= `OPT_ICALC;
                    7'b0110011: decryptedOPtype <= `OPT_R;
                    7'b0001111: decryptedOPtype <= `OPT_FENCE; //fence
                    7'b1110011: decryptedOPtype <= `OPT_SYSTEM; //ecall/ebreak
                    default: decryptedOPtype <= `OPT_INVALID; //error case
                endcase


            2: //decode specific type and write to output
                case(decryptedOPtype)
                    `OPT_LUI: begin //LUI U
                        imm <= {instruction[31:12], {12{1'b0}}};
                        rd <= instruction[11:7];
                        rs1 <= 5'bz;
                        rs2 <= 5'bz;
                        shamt <= 5'bz;
                        pc_increment <= 4;
                        Instruction_to_CU <= `CU_LUI;
                        invalid_instruction <= 0;
                    end
                    `OPT_AUIPC: begin//AUIPC U
                        imm <= {instruction[31:12], {12{1'b0}}};
                        rd <= instruction[11:7];
                        rs1 <= 5'bz;
                        rs2 <= 5'bz;
                        shamt <= 5'bz;
                        pc_increment <= 4;
                        Instruction_to_CU <= `CU_AUIPC;
                        invalid_instruction <= 0;
                    end
                    `OPT_JAL: begin//JAL J
                        imm <= 32'b0;
                        rd <= instruction[11:7];
                        rs1 <= 5'bz;
                        rs2 <= 5'bz;
                        shamt <= 5'bz;
                        pc_increment <= {{11{instruction[31]}}, instruction[31], instruction[19:12], instruction[20], instruction[30:21],1'b0}; //note the ending with 1'b0 as jumps must be aligned to the nearest 2 bytes to accommodate for R16 instructions.
                        Instruction_to_CU <= `CU_JAL;
                        invalid_instruction <= 0;
                    end
                    `OPT_JALR: begin//JALR J
                        imm <= {{20{instruction[31]}}, instruction[31:20]}; //same logic as above, but note that the lsb does not need to be 0 as rs1 + imm can both be odd and result in an even address. if it doesn't, make sure to cut off the last bit.
                        rd <= instruction[11:7];
                        rs1 <= instruction[19:15];
                        rs2 <= 5'bz;
                        shamt <= 5'bz;
                        pc_increment <= 4;
                        Instruction_to_CU <= `CU_JALR;
                        invalid_instruction <= 0;
                    end
                    `OPT_B: begin//B
                        imm <= {{19{instruction[31]}}, instruction[31], instruction[7], instruction[30:25], instruction[11:8], 1'b0};
                        rd <= 5'bz;
                        rs1 <= instruction[19:15];
                        rs2 <= instruction[24:20];
                        shamt <= 5'bz;
                        pc_increment <= 4;
                        invalid_instruction <= 0;
                        case(instruction[14:12])
                            3'b000: Instruction_to_CU <= `CU_BEQ; //beq
                            3'b001: Instruction_to_CU <= `CU_BNE; //bne
                            3'b100: Instruction_to_CU <= `CU_BLT; //blt
                            3'b101: Instruction_to_CU <= `CU_BGE; //bge
                            3'b110: Instruction_to_CU <= `CU_BLTU; //bltu
                            3'b111: Instruction_to_CU <= `CU_BGEU; //bgeu
                            default: invalid_instruction <= 1;
                        endcase
                    end
                    `OPT_S: begin//S
                        imm <= {{20{instruction[31]}}, instruction[31], instruction[30:25], instruction[11:7]};
                        rd <= 5'bz;
                        rs1 <= instruction[19:15];
                        rs2 <= instruction[24:20];
                        shamt <= 5'bz;
                        pc_increment <= 4;
                        invalid_instruction <= 0;
                        case(instruction[14:12])
                            3'b000: Instruction_to_CU <= `CU_SB; //sb
                            3'b001: Instruction_to_CU <= `CU_SH; //sh
                            3'b010: Instruction_to_CU <= `CU_SW; //sw
                            default: invalid_instruction <= 1;
                        endcase
                    end
                    `OPT_LOAD: begin//IG1 I (load)
                        imm <= {{20{instruction[31]}}, instruction[31:20]};
                        rd <= instruction[11:7];
                        rs1 <= instruction[19:15];
                        rs2 <= 5'bz;
                        shamt <= 5'bz;
                        pc_increment <= 4;
                        invalid_instruction <= 0;
                        case(instruction[14:12])
                            3'b000: Instruction_to_CU <= `CU_LB; //lb
                            3'b001: Instruction_to_CU <= `CU_LH; //lh
                            3'b010: Instruction_to_CU <= `CU_LW; //lw
                            3'b100: Instruction_to_CU <= `CU_LBU; //lbu
                            3'b101: Instruction_to_CU <= `CU_LHU; //lhu
                            default: invalid_instruction <= 1;
                        endcase
                    end
                    `OPT_ICALC: begin//IG2 I (calc)
                        rd <= instruction[11:7];
                        rs1 <= instruction[19:15];
                        rs2 <= 5'bz;
                        pc_increment <= 4;
                        invalid_instruction <= 0;
                        case(instruction[14:12])
                            3'b000: begin //addi
                                Instruction_to_CU <= `CU_ADDI; 
                                imm <= {{20{instruction[31]}}, instruction[31:20]};
                                shamt <= 5'bz;
                            end
                            3'b010: begin //slti
                                Instruction_to_CU <= `CU_SLTI; 
                                imm <= {{20{instruction[31]}}, instruction[31:20]};
                                shamt <= 5'bz;
                            end
                            3'b011: begin //sltiu
                                Instruction_to_CU <= `CU_SLTIU; 
                                imm <= {{20{instruction[31]}}, instruction[31:20]};
                                shamt <= 5'bz;
                            end
                            3'b100: begin //xori
                                Instruction_to_CU <= `CU_XORI;
                                imm <= {{20{instruction[31]}}, instruction[31:20]};
                                shamt <= 5'bz;
                            end
                            3'b110: begin //ori
                                Instruction_to_CU <= `CU_ORI;
                                imm <= {{20{instruction[31]}}, instruction[31:20]};
                                shamt <= 5'bz;
                            end
                            3'b111: begin //andi
                                Instruction_to_CU <= `CU_ANDI;
                                imm <= {{20{instruction[31]}}, instruction[31:20]};
                                shamt <= 5'bz;
                            end


                            3'b001: begin
                                Instruction_to_CU <= `CU_SLLI;
                                imm <= 32'bz;
                                shamt <= instruction[24:20];
                            end

                            3'b101: begin
                                if(!instruction[30]) begin
                                    Instruction_to_CU <= `CU_SRLI;
                                    imm <= 32'bz;
                                    shamt <= instruction[24:20];
                                end else begin
                                    Instruction_to_CU <= `CU_SRAI;
                                    imm <= 32'bz;
                                    shamt <= instruction[24:20];
                                end
                            end

                            default: invalid_instruction <= 1;
                        endcase
                    end

                    `OPT_R: begin//R
                        imm <= 32'bz;
                        rd <= instruction[11:7];
                        rs1 <= instruction[19:15];
                        rs2 <= instruction[24:20];
                        shamt <= 5'bz;
                        pc_increment <= 4;
                        invalid_instruction <= 0;
                        case(instruction[14:12])
                            3'b000: begin
                                if(!instruction[30]) begin //add
                                    Instruction_to_CU <= `CU_ADD;
                                end else begin //sub
                                    Instruction_to_CU <= `CU_SUB;
                                end
                            end
                            3'b001: Instruction_to_CU <= `CU_SLL; //sll
                            3'b010: Instruction_to_CU <= `CU_SLT; //slt
                            3'b011: Instruction_to_CU <= `CU_SLTU; //sltu
                            3'b100: Instruction_to_CU <= `CU_XOR; //xor
                            3'b101: begin 
                                if(!instruction[30]) begin //srl
                                    Instruction_to_CU <= `CU_SRL;
                                end else begin //sra
                                    Instruction_to_CU <= `CU_SRA;
                                end
                            end
                            3'b110: Instruction_to_CU <= `CU_OR; //or
                            3'b111: Instruction_to_CU <= `CU_AND; //and
                            default: invalid_instruction <= 1;
                        endcase
                    end
                    `OPT_FENCE: begin//FENCE/FENCE.I
                        imm <= 32'bz;
                        rd <= 5'bz;
                        rs1 <= 5'bz;
                        rs2 <= 5'bz;
                        shamt <= 5'bz;
                        pc_increment <= 4;
                        invalid_instruction <= 0;
                        case(instruction[14:12])
                            3'b000: Instruction_to_CU <= `CU_FENCE; //fence
                            3'b001: Instruction_to_CU <= `CU_FENCE_I; //fence.i
                            default: invalid_instruction <= 1;
                        endcase
                    end
                    `OPT_SYSTEM: begin//ECALL/EBREAK
                        case(instruction[20])
                            1'b0: begin
                                Instruction_to_CU <= `CU_ECALL; //ecall
                                decryptedOPtype <= `OPT_INITIAL;
                                imm <= 32'bz;
                                rd <= 5'bz;
                                rs1 <= 5'bz;
                                rs2 <= 5'bz;
                                shamt <= 5'bz;
                                pc_increment <= 4;
                                invalid_instruction <= 0;
                            end
                            1'b1: Instruction_to_CU <= `CU_EBREAK; //ebreak means no reset
                        endcase
                    end

                   // `OPT_INITIAL: begin//INITIALIZED
                   //     imm <= 32'bz;
                   //     rd <= 5'bz;
                   //     rs1 <= 5'bz;
                   //     rs2 <= 5'bz;
                   //     shamt <= 5'bz;
                   //     pc_increment <= 4;
                   //     invalid_instruction <= 0;
                   // end

                    default: begin //ERROR. should catch 11 case
                        $finish;
                    end
                endcase

            3: //no operation
                begin end
        endcase
    end
end

endmodule