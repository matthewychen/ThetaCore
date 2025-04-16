module ALU_top(
    //templated
    input soc_clk,
    input reset,
    input dat_ready, //CU processing finished

    //databusses
    input [31:0] ALU_dat1,
    input [31:0] ALU_dat2,
    input [2:0] ALU_opcode, //from [14:12] of instruction

    input ALU_opcode_differentiator, //purely for use of ADD/SUB, SRI/SRA, SRLI/SRAI differentiator. from [2] of instruction.
        //1'b0 -> default state
        //1'b1 -> indicates SUB, SRA, or SRAI operation

    input ALU_optype, //
        //1'b1 -> I/R type (ALU_out needs calculation)
        //1'b0 -> B type (ALU_out redundant, all that is needed is branching flag)
    input [4:0] Instruction_to_ALU,

    //flags
    output reg ALU_overflow,
    output reg ALU_con_met, //branching and SLTI flag
    output reg ALU_zero,
    output reg ALU_err,
    output reg ALU_ready,

    //to CU
    output reg [31:0] ALU_out
    );

    //for storage to mitigate data loss
    reg [31:0] reg_ALU_dat1;
    reg [31:0] reg_ALU_dat2;
    reg [2:0] reg_ALU_opcode;
    reg  reg_ALU_optype;
    reg [4:0] reg_concat_op;

    reg [1:0] ALU_result_counter;
    
    reg [31:0] AddSub_out;
    reg [31:0] Comparator_out; //always 32b0
    reg [31:0] LogOp_out;
    reg [31:0] Shifter_out;

    initial begin
        ALU_overflow = 1'b0;
        ALU_con_met = 1'b0;
        ALU_zero = 1'b0;
        ALU_err = 1'b0;

        ALU_out <= 32'b0;

        reg_ALU_dat1 = 32'b0;
        reg_ALU_dat2 = 32'b0;
        reg_ALU_opcode = 3'b0;
        reg_ALU_optype = 1'b0;
        reg_concat_op = 5'b0;

        ALU_out <= 0;

        ALU_result_counter = 2'b0;
    end

    always@(posedge dat_ready) begin //preserve to avoid dataloss
        reg_ALU_dat1 <= ALU_dat1;
        reg_ALU_dat2 <= ALU_dat2;
        reg_ALU_opcode <= ALU_opcode;
        reg_ALU_optype <= ALU_optype;
    end

    always@(posedge reset) begin //reset on data no longer ready
        reg_ALU_dat1 <= 0;
        reg_ALU_dat2 <= 0;
        reg_ALU_opcode <= 0;
        reg_ALU_optype <= 0;
    end

    always@(reg_ALU_optype, ALU_opcode_differentiator, reg_ALU_opcode) begin
        reg_concat_op <= {reg_ALU_optype, ALU_opcode_differentiator, reg_ALU_opcode};
    end

    //decryptor - MIGRATED TO IDU_top.
 //   always@(reg_concat_op) begin //IMPORTANT: need to account for situations where IMM places a 1 in reg_ALU_optype
 //       case(reg_concat_op)

 //           //B
 //           5'b10000: Instruction_to_ALU = 5'd0; //BEQ branch equal
 //           5'b10001: Instruction_to_ALU = 5'd1; //BNE branch not equal
 //           5'b10100: Instruction_to_ALU = 5'd2; //BLT branch less than
 //           5'b10101: Instruction_to_ALU = 5'd3; //BGE branch greater than or equal
 //           5'b10110: Instruction_to_ALU = 5'd4; //BLTU branch less than unsigned
 //           5'b10111: Instruction_to_ALU = 5'd5; //BGEU branch greater than or equal unsigned

 //           //I/R
 //           5'b00000: Instruction_to_ALU = 5'd6; //ADD/ADDI add 
 //           5'b01000: Instruction_to_ALU = 5'd7; //SUB subtract 
 //           5'b00001: Instruction_to_ALU = 5'd8; //SLL/SLLI logical leftshift 
 //           5'b00010: Instruction_to_ALU = 5'd9; //SLT/SLTI set less than
 //           5'b00011: Instruction_to_ALU = 5'd10; //SLTU set less than unsigned
 //           5'b00100: Instruction_to_ALU = 5'd11; //XOR/XORI xor 
 //           5'b00101: Instruction_to_ALU = 5'd12; //SRL/SRLI logical rightshift 
 //           5'b01101: Instruction_to_ALU = 5'd13; //SRA/SRAI arithmetic rightshift 
 //           5'b00110: Instruction_to_ALU = 5'd14; //OR/ORI or
 //           5'b00111: Instruction_to_ALU = 5'd15; //AND/ANDI and

 //           default: Instruction_to_ALU = 5'd16; //throw error flag
 //       endcase
 //   end

    always@(posedge soc_clk) begin //counter output
        if(dat_ready) begin
            if(ALU_result_counter == 0 || ALU_result_counter == 1 || ALU_result_counter == 2) begin //reset all outputs
                ALU_out <= 32'b0;
                ALU_overflow <= 1'b0;
                ALU_zero <= 1'b0;
                ALU_con_met <= 1'b0;
                ALU_result_counter <= ALU_result_counter + 1;
            end
            if(ALU_result_counter == 3) begin //output
                ALU_ready <= 1;
                if(Instruction_to_ALU == 6 || Instruction_to_ALU == 7) begin
                    ALU_out <= AddSub_out;
                    ALU_overflow <= AddSub_overflow;
                    ALU_zero <= AddSub_zero;
                end
                else if (Instruction_to_ALU == 8 || Instruction_to_ALU == 12 || Instruction_to_ALU == 13) begin
                    ALU_out <= Shifter_out;
                end
                else if (Instruction_to_ALU == 14 || Instruction_to_ALU == 15 || Instruction_to_ALU == 11) begin
                    ALU_out <= LogOp_out;
                end
                else if (Instruction_to_ALU == 0 || Instruction_to_ALU == 1 || Instruction_to_ALU == 2 || Instruction_to_ALU == 3 || Instruction_to_ALU == 4 || Instruction_to_ALU == 5 || Instruction_to_ALU == 9 || Instruction_to_ALU == 10) begin
                    ALU_out <= Comparator_out;
                    ALU_con_met <= Comparator_con_met;
                end
                else if (Instruction_to_ALU == 16) begin //no operation
                    ALU_out <= 32'b0;
                end
                ALU_result_counter <= 0;
            end
        end
        else begin
            ALU_ready <= 0;
        end
    end

    //instantiations
    AddSub AS(
        .soc_clk(soc_clk),
        .reset(reset),
        .dat_ready(dat_ready),
        .ALU_dat1(reg_ALU_dat1),
        .ALU_dat2(reg_ALU_dat2),
        .Instruction_to_ALU(Instruction_to_ALU),
        .AddSub_out(AddSub_out),
        .AddSub_overflow(AddSub_overflow),
        .AddSub_zero(AddSub_zero)
    );

    Comparator C(
        .soc_clk(soc_clk),
        .reset(reset),
        .dat_ready(dat_ready),
        .ALU_dat1(reg_ALU_dat1),
        .ALU_dat2(reg_ALU_dat2),
        .Instruction_to_ALU(Instruction_to_ALU),
        .Comparator_out(Comparator_out),
        .Comparator_con_met(Comparator_con_met)
    );

    LogOp LO(
        .soc_clk(soc_clk),
        .reset(reset),
        .dat_ready(dat_ready),
        .ALU_dat1(reg_ALU_dat1),
        .ALU_dat2(reg_ALU_dat2),
        .Instruction_to_ALU(Instruction_to_ALU),
        .LogOp_out(LogOp_out)
    );

    Shifter S(
        .soc_clk(soc_clk),
        .reset(reset),
        .dat_ready(dat_ready),
        .ALU_dat1(reg_ALU_dat1),
        .ALU_dat2(reg_ALU_dat2),
        .Instruction_to_ALU(Instruction_to_ALU),
        .Shifter_out(Shifter_out)
    );

endmodule