module SRAddress(
    input logic WL,
    input [31:0] datain,
    output reg [31:0] dataout
);

logic [31:0] BL1in;
logic [31:0] BL2in;

wire [31:0] BL1out;

always@(*) begin
    if(~WL) begin //undefined if WL not asserted; for safety purposes in SR cell interaction
        BL1in = 32'bz;
        BL2in = 32'bz;
    end else begin
        BL1in = datain;
        BL2in = ~datain;
    end
end

always@(posedge WL) begin //drive dataout if WL is enabled
    dataout <= BL1out;
end

//create 32 SRAM cells per address
genvar i;
generate
    for (i = 0; i < 32; i = i + 1) begin : SRAM_cells
        SRAMcell SRAMcell_inst(
            .WL(WL),
            .BL1in(BL1in[i]),
            .BL2in(BL2in[i]),
            .BL1out(BL1out[i])
        );
    end
endgenerate

endmodule