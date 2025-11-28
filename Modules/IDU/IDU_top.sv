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
        decryptedOPtype <= 12;
        imm <= 32'bz;
        rd <= 5'bz;
        rs1 <= 5'bz;
        rs2 <= 5'bz;
        shamt <= 5'bz;
        pc_increment <= 4;
        Instruction_to_CU <= 0;
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
                    7'b0110111: decryptedOPtype <= 0;
                    7'b0010111: decryptedOPtype <= 1;
                    7'b1101111: decryptedOPtype <= 2;
                    7'b1100111: decryptedOPtype <= 3;
                    7'b1100011: decryptedOPtype <= 4;
                    7'b0100011: decryptedOPtype <= 5;
                    7'b0000011: decryptedOPtype <= 6;
                    7'b0010011: decryptedOPtype <= 7;
                    7'b0110011: decryptedOPtype <= 8;
                    7'b0001111: decryptedOPtype <= 9; //fence
                    7'b1110011: decryptedOPtype <= 10; //ecall/ebreak
                    default: decryptedOPtype <= 11; //error case
                endcase


            2: //decode specific type and write to output
                case(decryptedOPtype)
                    4'd0: begin //LUI U
                        imm <= {instruction[31:12], {12{1'b0}}};
                        rd <= instruction[11:7];
                        rs1 <= 5'bz;
                        rs2 <= 5'bz;
                        shamt <= 5'bz;
                        pc_increment <= 4;
                        Instruction_to_CU <= 0;
                        invalid_instruction <= 0;
                    end
                    4'd1: begin//AUIPC U
                        imm <= {instruction[31:12], {12{1'b0}}};
                        rd <= instruction[11:7];
                        rs1 <= 5'bz;
                        rs2 <= 5'bz;
                        shamt <= 5'bz;
                        pc_increment <= 4;
                        Instruction_to_CU <= 1;
                        invalid_instruction <= 0;
                    end
                    4'd2: begin//JAL J
                        imm <= 32'b0;
                        rd <= instruction[11:7];
                        rs1 <= 5'bz;
                        rs2 <= 5'bz;
                        shamt <= 5'bz;
                        pc_increment <= {{11{instruction[31]}}, instruction[31], instruction[19:12], instruction[20], instruction[30:21],1'b0}; //note the ending with 1'b0 as jumps must be aligned to the nearest 2 bytes to accommodate for R16 instructions.
                        Instruction_to_CU <= 2;
                        invalid_instruction <= 0;
                    end
                    4'd3: begin//JALR J
                        imm <= {{20{instruction[31]}}, instruction[31:20]}; //same logic as above, but note that the lsb does not need to be 0 as rs1 + imm can both be odd and result in an even address. if it doesn't, make sure to cut off the last bit.
                        rd <= instruction[11:7];
                        rs1 <= instruction[19:15];
                        rs2 <= 5'bz;
                        shamt <= 5'bz;
                        pc_increment <= 4;
                        Instruction_to_CU <= 3;
                        invalid_instruction <= 0;
                    end
                    4'd4: begin//B
                        imm <= {{19{instruction[31]}}, instruction[31], instruction[7], instruction[30:25], instruction[11:8], 1'b0};
                        rd <= 5'bz;
                        rs1 <= instruction[19:15];
                        rs2 <= instruction[24:20];
                        shamt <= 5'bz;
                        pc_increment <= 4;
                        invalid_instruction <= 0;
                        case(instruction[14:12])
                            3'b000: Instruction_to_CU <= 4; //beq
                            3'b001: Instruction_to_CU <= 5; //bne
                            3'b100: Instruction_to_CU <= 6; //blt
                            3'b101: Instruction_to_CU <= 7; //bge
                            3'b110: Instruction_to_CU <= 8; //bltu
                            3'b111: Instruction_to_CU <= 9; //bgeu
                            default: invalid_instruction <= 1;
                        endcase
                    end
                    4'd5: begin//S
                        imm <= {{20{instruction[31]}}, instruction[31], instruction[30:25], instruction[11:7]};
                        rd <= 5'bz;
                        rs1 <= instruction[19:15];
                        rs2 <= instruction[24:20];
                        shamt <= 5'bz;
                        pc_increment <= 4;
                        invalid_instruction <= 0;
                        case(instruction[14:12])
                            3'b000: Instruction_to_CU <= 10; //sb
                            3'b001: Instruction_to_CU <= 11; //sh
                            3'b010: Instruction_to_CU <= 12; //sw
                            default: invalid_instruction <= 1;
                        endcase
                    end
                    4'd6: begin//IG1 I (load)
                        imm <= {{20{instruction[31]}}, instruction[31:20]};
                        rd <= instruction[11:7];
                        rs1 <= instruction[19:15];
                        rs2 <= 5'bz;
                        shamt <= 5'bz;
                        pc_increment <= 4;
                        invalid_instruction <= 0;
                        case(instruction[14:12])
                            3'b000: Instruction_to_CU <= 13; //lb
                            3'b001: Instruction_to_CU <= 14; //lh
                            3'b010: Instruction_to_CU <= 15; //lw
                            3'b100: Instruction_to_CU <= 16; //lbu
                            3'b101: Instruction_to_CU <= 17; //lhu
                            default: invalid_instruction <= 1;
                        endcase
                    end
                    4'd7: begin//IG2 I (calc)
                        rd <= instruction[11:7];
                        rs1 <= instruction[19:15];
                        rs2 <= 5'bz;
                        pc_increment <= 4;
                        invalid_instruction <= 0;
                        case(instruction[14:12])
                            3'b000: begin //addi
                                Instruction_to_CU <= 18; 
                                imm <= {{20{instruction[31]}}, instruction[31:20]};
                                shamt <= 5'bz;
                            end
                            3'b010: begin //slti
                                Instruction_to_CU <= 19; 
                                imm <= {{20{instruction[31]}}, instruction[31:20]};
                                shamt <= 5'bz;
                            end
                            3'b011: begin //sltiu
                                Instruction_to_CU <= 20; 
                                imm <= {{20{instruction[31]}}, instruction[31:20]};
                                shamt <= 5'bz;
                            end
                            3'b100: begin //xori
                                Instruction_to_CU <= 21;
                                imm <= {{20{instruction[31]}}, instruction[31:20]};
                                shamt <= 5'bz;
                            end
                            3'b110: begin //ori
                                Instruction_to_CU <= 22;
                                imm <= {{20{instruction[31]}}, instruction[31:20]};
                                shamt <= 5'bz;
                            end
                            3'b111: begin //andi
                                Instruction_to_CU <= 23;
                                imm <= {{20{instruction[31]}}, instruction[31:20]};
                                shamt <= 5'bz;
                            end


                            3'b001: begin
                                Instruction_to_CU <= 24;
                                imm <= 32'bz;
                                shamt <= instruction[24:20];
                            end

                            3'b101: begin
                                if(!instruction[30]) begin
                                    Instruction_to_CU <= 25;
                                    imm <= 32'bz;
                                    shamt <= instruction[24:20];
                                end else begin
                                    Instruction_to_CU <= 26;
                                    imm <= 32'bz;
                                    shamt <= instruction[24:20];
                                end
                            end

                            default: invalid_instruction <= 1;
                        endcase
                    end

                    4'd8: begin//R
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
                                    Instruction_to_CU <= 27;
                                end else begin //sub
                                    Instruction_to_CU <= 28;
                                end
                            end
                            3'b001: Instruction_to_CU <= 29; //sll
                            3'b010: Instruction_to_CU <= 30; //slt
                            3'b011: Instruction_to_CU <= 31; //sltu
                            3'b100: Instruction_to_CU <= 32; //xor
                            3'b101: begin 
                                if(!instruction[30]) begin //srl
                                    Instruction_to_CU <= 33;
                                end else begin //sra
                                    Instruction_to_CU <= 34;
                                end
                            end
                            3'b110: Instruction_to_CU <= 35; //or
                            3'b111: Instruction_to_CU <= 36; //and
                            default: invalid_instruction <= 1;
                        endcase
                    end
                    4'd9: begin//FENCE/FENCE.I
                        imm <= 32'bz;
                        rd <= 5'bz;
                        rs1 <= 5'bz;
                        rs2 <= 5'bz;
                        shamt <= 5'bz;
                        pc_increment <= 4;
                        invalid_instruction <= 0;
                        case(instruction[14:12])
                            3'b000: Instruction_to_CU <= 37; //fence
                            3'b001: Instruction_to_CU <= 38; //fence.i
                            default: invalid_instruction <= 1;
                        endcase
                    end
                    4'd10: begin//ECALL/EBREAK
                        case(instruction[20])
                            1'b0: begin
                                Instruction_to_CU <= 39; //ecall
                                decryptedOPtype <= 12;
                                imm <= 32'bz;
                                rd <= 5'bz;
                                rs1 <= 5'bz;
                                rs2 <= 5'bz;
                                shamt <= 5'bz;
                                pc_increment <= 4;
                                invalid_instruction <= 0;
                            end
                            1'b1: Instruction_to_CU <= 40; //ebreak means no reset
                        endcase
                    end

                   // 4'd12: begin//INITIALIZED
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