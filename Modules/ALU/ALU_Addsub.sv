module AddSub(
    input soc_clk,
    input reset,
    input dat_ready,
    input [31:0] ALU_dat1,
    input [31:0] ALU_dat2,
    input [4:0] Instruction_to_ALU,

    output [31:0] AddSub_out,
    output AddSub_overflow
);

reg [31:0] RA_dat1;
reg [31:0] RA_dat2;
wire [31:0] TC_dat2;
wire [32:0] AddSub_int;

always@(posedge soc_clk) begin
    if (reset) begin
        RA_dat1 <= 32'b0;
        RA_dat2 <= 32'b0;
    end
    else if (dat_ready) begin
        if (Instruction_to_ALU == 5'd6) begin // ADD
            RA_dat1 <= ALU_dat1;
            RA_dat2 <= ALU_dat2;
        end
        else if (Instruction_to_ALU == 5'd7) begin // SUB
            RA_dat1 <= ALU_dat1;
            RA_dat2 <= TC_dat2;
        end
        else begin
            // Not an add/sub op; hold last values
            RA_dat1 <= 32'b0;
            RA_dat2 <= 32'b0;
        end
    end
end

assign AddSub_out = AddSub_int[31:0];
assign AddSub_overflow = (RA_dat1[31] ^ AddSub_int[31]) & (RA_dat2[31] ^ ((Instruction_to_ALU == 7) ? AddSub_int[31] : RA_dat1[31]));

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