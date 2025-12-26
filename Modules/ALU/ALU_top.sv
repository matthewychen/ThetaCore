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
        output ALU_accept
        );

        //for storage to mitigate data loss
        reg [4:0] Instruction_to_ALU;
        reg [31:0] reg_ALU_dat1;
        reg [31:0] reg_ALU_dat2;

        reg [1:0] ALU_result_counter;
        
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
                Instruction_to_ALU <= 5'd16;
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
                            4: Instruction_to_ALU <= 5'd0; //BEQ branch equal
                            5: Instruction_to_ALU <= 5'd1; //BNE branch not equal
                            6: Instruction_to_ALU <= 5'd2; //BLT branch less than
                            7: Instruction_to_ALU <= 5'd3; //BGE branch greater than or equal
                            8: Instruction_to_ALU <= 5'd4; //BLTU branch less than unsigned
                            9: Instruction_to_ALU <= 5'd5; //BGEU branch greater than or equal unsigned

                            //I/R
                            27: Instruction_to_ALU <= 5'd6; //ADD add 
                            18: Instruction_to_ALU <= 5'd6; //ADDI add 
                            28: Instruction_to_ALU <= 5'd7; //SUB subtract 
                            29: Instruction_to_ALU <= 5'd8; //SLL logical leftshift 
                            24: Instruction_to_ALU <= 5'd8; //SLLI logical leftshift
                            30: Instruction_to_ALU <= 5'd9; //SLT set less than
                            19: Instruction_to_ALU <= 5'd9; //SLTI set less than
                            31: Instruction_to_ALU <= 5'd10; //SLTU set less than unsigned
                            32: Instruction_to_ALU <= 5'd11; //XOR xor 
                            21: Instruction_to_ALU <= 5'd11; //XORI xor 
                            33: Instruction_to_ALU <= 5'd12; //SRL logical rightshift 
                            25: Instruction_to_ALU <= 5'd12; //SRLI logical rightshift 
                            34: Instruction_to_ALU <= 5'd13; //SRA arithmetic rightshift
                            26: Instruction_to_ALU <= 5'd13; //SRAI arithmetic rightshift 
                            35: Instruction_to_ALU <= 5'd14; //OR or
                            22: Instruction_to_ALU <= 5'd14; //ORI or
                            36: Instruction_to_ALU <= 5'd15; //AND and
                            23: Instruction_to_ALU <= 5'd15; //ANDI and
                            default: Instruction_to_ALU <= 5'd16; //no operation
                            endcase
                            ALU_result_counter <= 2'b10;
                    end
                    2'b10: begin 
                        ALU_result_counter <= 2'b11;
                        case(Instruction_to_ALU)
                            6, 7: begin
                                ALU_out <= AddSub_out;
                                ALU_overflow <= AddSub_overflow;
                                ALU_zero <= ~|AddSub_out;
                                ALU_con_met <= 0;
                            end
                            8, 12, 13: begin ALU_out <= Shifter_out;
                                ALU_overflow <= 0;
                                ALU_zero <= ~|Shifter_out;
                                ALU_con_met <= 0;
                            end
                            11, 14, 15: begin ALU_out <= LogOp_out;
                                ALU_overflow <= 0;
                                ALU_zero <= ~|LogOp_out;
                                ALU_con_met <= 0;
                            end
                            0, 1, 2, 3, 4, 5, 9, 10: begin
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


        //IMPLEMENT THE DECODING:
            //specific instructions for ALU
        /*
        always@(*) begin 
            case(Instruction_from_CU)
                //B
                4: Instruction_to_ALU = 5'd0; //BEQ branch equal
                5: Instruction_to_ALU = 5'd1; //BNE branch not equal
                6: Instruction_to_ALU = 5'd2; //BLT branch less than
                7: Instruction_to_ALU = 5'd3; //BGE branch greater than or equal
                8: Instruction_to_ALU = 5'd4; //BLTU branch less than unsigned
                9: Instruction_to_ALU = 5'd5; //BGEU branch greater than or equal unsigned

                //I/R
                27: Instruction_to_ALU = 5'd6; //ADD add 
                18: Instruction_to_ALU = 5'd6; //ADDI add 
                28: Instruction_to_ALU = 5'd7; //SUB subtract 
                29: Instruction_to_ALU = 5'd8; //SLL logical leftshift 
                24: Instruction_to_ALU = 5'd8; //SLLI logical leftshift
                30: Instruction_to_ALU = 5'd9; //SLT set less than
                19: Instruction_to_ALU = 5'd9; //SLTI set less than
                31: Instruction_to_ALU = 5'd10; //SLTU set less than unsigned
                32: Instruction_to_ALU = 5'd11; //XOR xor 
                21: Instruction_to_ALU = 5'd11; //XORI xor 
                33: Instruction_to_ALU = 5'd12; //SRL logical rightshift 
                25: Instruction_to_ALU = 5'd12; //SRLI logical rightshift 
                34: Instruction_to_ALU = 5'd13; //SRA arithmetic rightshift
                26: Instruction_to_ALU = 5'd13; //SRAI arithmetic rightshift 
                35: Instruction_to_ALU = 5'd14; //OR or
                22: Instruction_to_ALU = 5'd14; //ORI or
                36: Instruction_to_ALU = 5'd15; //AND and
                23: Instruction_to_ALU = 5'd15; //ANDI and

                default: Instruction_to_ALU = 5'd16; //no operation
            endcase
    end
    */

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