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

genvar i;
generate
    for (i = 0; i < 8; i = i + 1) begin : SRAM_cells
        SRAMcell SRAMcell_inst(
            .WL(WL),
            .BL1in(BL1in[i]),
            .BL2in(BL2in[i]),
            .BL1out(BL1out[i]),
            .read_pulse(read_pulse),
            .write_pulse(write_pulse)
        );
    end
endgenerate

always @(negedge read_pulse) begin
    if (WL) begin
        dataout <= BL1out;
    end
end

endmodule