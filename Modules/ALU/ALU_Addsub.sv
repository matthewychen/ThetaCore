module AddSub(
    input soc_clk,
    input reset,
    input [31:0] ALU_dat1,
    input [31:0] ALU_dat2,
    input [4:0] Instruction_to_ALU,
    output [31:0] AddSub_out,
    output AddSub_overflow
);

wire [31:0] RA_dat1;
wire [31:0] RA_dat2;
wire [31:0] TC_dat2;
wire [32:0] AddSub_int;


assign RA_dat1 = ALU_dat1;

assign RA_dat2 =
    (Instruction_to_ALU == 7) ? TC_dat2 :   // SUB
    (Instruction_to_ALU == 6) ? ALU_dat2 :  // ADD
                                32'b0;


assign AddSub_out = AddSub_int[31:0];
assign AddSub_overflow =
    (Instruction_to_ALU == 6) ?  // ADD
        (~ALU_dat1[31] & ~ALU_dat2[31] &  AddSub_int[31]) |
        ( ALU_dat1[31] &  ALU_dat2[31] & ~AddSub_int[31])
    :
    (Instruction_to_ALU == 7) ?  // SUB
        ( ALU_dat1[31] & ~ALU_dat2[31] & ~AddSub_int[31]) |
        (~ALU_dat1[31] &  ALU_dat2[31] &  AddSub_int[31])
    :
    1'b0;

//instantiations
//ADDSUB
rippleadder RA( //comb blocks
    .A(RA_dat1),
    .B(RA_dat2),
    .SUM(AddSub_int)
);

twoscomp TC(
    .in(ALU_dat2),
    .out(TC_dat2)
);

endmodule