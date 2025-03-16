//gate level implementation
module AddSub(
    //templated
    input soc_clk,
    input reset,
    input dat_ready,
    input [31:0] ALU_dat1,
    input [31:0] ALU_dat2,
    input [2:0] ALU_opcode,
    input [3:0] decryptedOP,

    output [31:0] AddSub_out,

    output AddSub_overflow,
    output AddSub_zero
);

reg [31:0] RA_dat1;
reg [31:0] RA_dat2;
wire [31:0] TC_dat2;
wire [32:0] AddSub_superint;

always@(posedge soc_clk) begin
    if (reset || ~dat_ready) begin
        RA_dat1 <= 32'b0;
        RA_dat2 <= 32'b0;
    end
    else begin
        if (decryptedOP == 6) begin
            RA_dat1 <= ALU_dat1;
            RA_dat2 <= ALU_dat2;
        end
        else if (decryptedOP == 7) begin
            RA_dat1 <= ALU_dat1;
            RA_dat2 <= TC_dat2;
        end
        else begin
            RA_dat1 <= 32'b0;
            RA_dat2 <= 32'b0;
        end
    end
end

assign AddSub_out = AddSub_superint[31:0];
assign AddSub_overflow = AddSub_superint[32];
assign AddSub_zero = ~(|AddSub_superint[31:0]);

//instantiations
rippleadder RA(
    .A(RA_dat1),
    .B(RA_dat2),
    .SUM(AddSub_superint)
);

twoscomp TC(
    .in(ALU_dat2),
    .out(TC_dat2)
);

endmodule