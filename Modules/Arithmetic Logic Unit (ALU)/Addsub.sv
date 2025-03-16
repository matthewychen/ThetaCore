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

reg [32:0] AddSub_superint;

always@(posedge soc_clk) begin
    if (reset) begin
        AddSub_superint <= 33'b0;
    end
    else if (dat_ready) begin
        if (decryptedOP == 6) begin
            AddSub_superint <= ALU_dat1 + ALU_dat2;
        end
        else if (decryptedOP == 7) begin
            AddSub_superint <= ALU_dat1 - ALU_dat2;
        end
        else begin
            AddSub_superint <= 33'b0;
        end
    end
end

assign AddSub_out = AddSub_superint[31:0];
assign AddSub_overflow = AddSub_superint[32];
assign AddSub_zero = ~(|AddSub_superint[31:0]);

endmodule