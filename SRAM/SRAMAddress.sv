module SRAMaddress(
    input  logic        clk,
    input  logic        wordline,
    input  logic [3:0]  byte_sel,
    input  logic [31:0] datain,
    input  logic        read_enable,
    input  logic        write_enable,
    output logic [31:0] dataout
);

    // Array to hold 4 bytes per address
    wire [7:0] dataout_bytes [3:0];

    // Instantiate 4 SRAM bytes per address
    genvar i;
    generate
        for (i = 0; i < 4; i = i + 1) begin : SRAM_bytes
            SRAMbyte SRAMbyte_inst(
                .clk(clk),
                .wordline(wordline & byte_sel[i]),
                .datain(datain[8*i +: 8]),
                .read_enable(read_enable),
                .write_enable(write_enable),
                .dataout(dataout_bytes[i])
            );
        end
    endgenerate

    // Combine the bytes into a 32-bit word
    assign dataout = {dataout_bytes[3], dataout_bytes[2], dataout_bytes[1], dataout_bytes[0]};

endmodule
