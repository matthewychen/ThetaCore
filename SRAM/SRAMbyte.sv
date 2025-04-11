module SRAMbyte(
    input logic WL,
    input [7:0] datain,
    output reg [7:0] dataout,

    input read_pulse,
    input write_pulse
);

logic [7:0] BL1in;
logic [7:0] BL2in;

wire [7:0] BL1out;

initial begin
    BL1in = 8'b0;
    BL2in = {8{1'b1}};
end

always@(*) begin
    if (WL && write_pulse) begin
        BL1in = datain;
        BL2in = ~datain;
    end
end

genvar k;
generate
    for (k = 0; k < 8; k = k + 1) begin : SRAM_cells
        SRAMcell SRAMcell_inst(
            .WL(WL),
            .BL1in(BL1in[k]),
            .BL2in(BL2in[k]),
            .BL1out(BL1out[k]),
            .read_pulse(read_pulse),
            .write_pulse(write_pulse)
        );
    end
endgenerate

assign dataout = BL1out;

endmodule