module SRAddress(
    input WL;
    input [31:0] datain,
    output [31:0] dataout
);

reg [31:0] BL1in;
reg [31:0] BL2in;

wire [31:0] BL1out;

always@(*) begin
    if(~WL) begin //undefined if WL not asserted; for safety purposes in SR cell interaction
        BL1in <= 32'bzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzz;
        BL2in <= 32'bzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzz;
    end
    BL1in <= datain;
    BL2in <= ~datain;
end

assign dataout = BL1out;

//create 32 SRAM cells per address
genvar i;
generate
    for (i = 0; i < 32; i = i + 1) begin : SRAM_cells
        SRAMcell SRAMcell_inst(
            .WL(WL),
            .BL1in(BL1in[i]),
            .BL2in(BL2in[i]),
            .BL1out(BL1out[i]),
            .BL2out(BL2out[i])
        );
    end
endgenerate

endmodule