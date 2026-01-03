module SRAMbyte(
    input  logic        clk,
    input  logic        wordline,
    input  logic [7:0]  datain,
    input  logic        read_enable,
    input  logic        write_enable,
    output wire [7:0]  dataout
);

    // Instantiate 8 SRAM cells
    genvar k;
    generate
        for (k = 0; k < 8; k = k + 1) begin : SRAM_cells
            SRAMcell SRAMcell_inst(
                .clk(clk),
                .wordline(wordline),
                .BL1in(datain[k]),
                .BL2in(~datain[k]),
                .read_enable(read_enable),
                .write_enable(write_enable),
                .BL1out(dataout[k])
            );
        end
    endgenerate

endmodule
