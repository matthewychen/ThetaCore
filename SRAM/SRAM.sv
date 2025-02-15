module SRAM(
    input [6:0] addr,
    input addr_ready,
    input read_pulse,
    input write_pulse,

    input [31:0] datain,
    output reg [31:0] dataout,

    output reg f_ready
);

reg [127:0] WL_sel;
wire [31:0] dataout_array [127:0];

initial begin
    WL_sel = 128'd0;
end

always @(posedge addr_ready) begin
    WL_sel[addr] = 1'b1; // Reset mask every cycle
    f_ready = 1;
end


always@(negedge addr_ready) begin
    WL_sel = 128'd0;
    f_ready <= 0;
end

genvar i;
generate
    for (i = 0; i < 128; i = i + 1) begin : SRAM_addrs
        SRAddress SRAddress_inst(
            .WL(WL_sel[i]),
            .datain(datain),
            .dataout(dataout_array[i]),
            .read_pulse(read_pulse),
            .write_pulse(write_pulse)
        );
    end
endgenerate

always@(negedge read_pulse) begin
    dataout <= dataout_array[addr];
end

endmodule