module ALU_top(
    //templated
    input soc_clk,
    input reset,
    input dat_ready,

    //databusses
    input [31:0] ALU_dat1,
    input [31:0] ALU_dat2,
    input [2:0] ALU_opcode, //from [14:12] of instruction

    input ALU_opcode_differentiator, //purely for use of ADD/SUB, SRI/SRA, SRLI/SRAI differentiator. from [2] of instruction.
        //1'b0 -> default state
        //1'b1 -> indicates SUB, SRA, or SRAI operation

    input  ALU_optype, //
        //1'b1 -> I/R type (ALU_out needs calculation)
        //1'b0 -> B type (ALU_out redundant, all that is needed is branching flag)

    //flags
    output ALU_overflow,
    output ALU_branch,
    output ALU_zero,

    //to CU
    output [31:0] ALU_out
    );

    //for storage to mitigate data loss
    reg [31:0] reg_ALU_dat1,
    reg [31:0] reg_ALU_dat2,
    reg [2:0] reg_ALU_opcode,
    reg  reg_ALU_optype, 
    reg [4:0] reg_concat_op;

    reg[3:0] decryptedOP;
    

    initial begin
        ALU_underflow = 1'b0;
        ALU_overflow = 1'b0;
        ALU_branch = 1'b0;
        ALU_zero = 1'b0;
        ALU_negative = 1'b0;
        ALU_out = 32'b0;

        reg_ALU_dat1 = 32'b0;
        reg_ALU_dat2 = 32'b0;
        reg_ALU_opcode = 3'b0;
        reg_ALU_optype = 1'b0;
        reg_concat_op = 5'b0;
    end

    always@(posedge dat_ready) begin //preserve to avoid dataloss
        reg_ALU_dat1 <= ALU_dat1;
        reg_ALU_dat2 <= ALU_dat2;
        reg_ALU_opcode <= ALU_opcode;
        reg_ALU_optype <= ALU_optype;
    end

    always@(negedge dat_ready or posedge reset_b) begin //reset on data no longer ready
        reg_ALU_dat1 <= 0;
        reg_ALU_dat2 <= 0;
        reg_ALU_opcode <= 0;
        reg_ALU_optype <= 0;
    end

    always@(reg_ALU_optype, ALU_opcode_differentiator, reg_ALU_opcode) begin
        reg_concat_op = {reg_ALU_optype, ALU_opcode_differentiator, reg_ALU_opcode};
    end

    //decryptor
    always@(reg_concat_op) begin
        case(reg_concat_op)

            //B
            5'b10000: decryptedOP = 5'd0; //BEQ branch equal
            5'b10001: decryptedOP = 5'd1; //BNE branch not equal
            5'b10100: decryptedOP = 5'd2; //BLT branch less than
            5'b10101: decryptedOP = 5'd3; //BGE branch greater than or equal
            5'b10110: decryptedOP = 5'd4; //BLTU branch less than unsigned
            5'b10111: decryptedOP = 5'd5; //BGEU branch greater than or equal unsigned

            //I/R
            5'b00000: decryptedOP = 5'd6; //ADD/ADDI add DONE
            5'b01000: decryptedOP = 5'd7; //SUB subtract DONE
            5'b00001: decryptedOP = 5'd8; //SLL/SLLI logical leftshift DONE
            5'b00010: decryptedOP = 5'd9; //SLT/SLTI set less than
            5'b00011: decryptedOP = 5'd10; //SLTU set less than unsigned
            5'b00100: decryptedOP = 5'd11; //XOR/XORI xor DONE
            5'b00101: decryptedOP = 5'd12; //SRL/SRLI logical rightshift DONE
            5'b01101: decryptedOP = 5'd13; //SRA/SRAI arithmetic rightshift DONE
            5'b00110: decryptedOP = 5'd14; //OR/ORI or DONE
            5'b00111: decryptedOP = 5'd15; //AND/ANDI and DONE

            default: decryptedOP = 5'dz; //invalid
        endcase
    end

    //TODO
    //need to implement 3 soc cycles after dat_ready to collect data according to decoded module


    //instantiations
    

endmodule