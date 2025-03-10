//maybe need seperate query clock?

module SRAMaddress(
    input logic WL,
    input [3:0] byte_sel,

    input [31:0] datain,
    output reg [31:0] dataout,

    input read_pulse,
    input write_pulse
);

// Declare an array to hold all output bytes
wire [7:0] dataout_bytes [3:0];

// Create 4 SRAM bytes per address
genvar i;
generate
    for (i = 0; i < 4; i = i + 1) begin : SRAM_bytes
        SRAMbyte SRAMbyte_inst(
            .WL(WL & byte_sel[i]),
            .datain(datain[8*i +: 8]),
            .dataout(dataout_bytes[i]),
            .read_pulse(read_pulse),
            .write_pulse(write_pulse)
        );
    end
endgenerate

// Combine the bytes into the 32-bit output
assign dataout = {dataout_bytes[3], dataout_bytes[2], dataout_bytes[1], dataout_bytes[0]};

endmodule