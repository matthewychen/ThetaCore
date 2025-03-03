module SRAM(
    input [6:0] addr_sel,
    input [3:0] byte_sel,

    input read_pulse,
    input write_pulse,

    input [31:0] datain,
    output reg [31:0] dataout

);

reg [127:0] WL_sel;
reg [3:0] addr_byte_sel;
wire [31:0] dataout_array [127:0];

initial begin
    WL_sel = 128'd0;
    addr_byte_sel = 4'd0;
end

always @(posedge read_pulse or posedge write_pulse) begin
    WL_sel[addr_sel] = 1'b1; // Reset mask every cycle
    addr_byte_sel = byte_sel;
end

always@(negedge read_pulse or negedge write_pulse) begin
    WL_sel = 128'd0;
end

genvar i;
generate
    for (i = 0; i < 128; i = i + 1) begin : SRAM_addrs
        SRAMAddress SRAMAddress_inst(
            .WL(WL_sel[i]),
            .byte_sel(addr_byte_sel),
            .datain(datain),
            .dataout(dataout_array[i]),
            .read_pulse(read_pulse),
            .write_pulse(write_pulse)
        );
    end
endgenerate

always@(*) begin
    dataout <= dataout_array[addr_sel];
end

endmodule