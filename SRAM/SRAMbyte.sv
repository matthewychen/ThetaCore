module SRAMbyte(
    input  logic        clk,
    input  logic        WL,
    input  logic [7:0]  datain,
    input  logic        read_enable,
    input  logic        write_enable,
    output logic [7:0]  dataout
);

    // Internal bitlines for storage
    reg [7:0] BL1in;
    reg [7:0] BL2in;

    wire [7:0] BL1out;

    // Initialize
    initial begin
        BL1in = 8'b0;
        BL2in = {8{1'b1}};
    end

    // Write operation (synchronous)
    always @(posedge clk) begin
        if (WL && write_enable) begin
            BL1in <= datain;
            BL2in <= ~datain;
        end
    end

    // Instantiate 8 SRAM cells
    genvar k;
    generate
        for (k = 0; k < 8; k = k + 1) begin : SRAM_cells
            SRAMcell SRAMcell_inst(
                .clk(clk),
                .WL(WL),
                .BL1in(BL1in[k]),
                .BL2in(BL2in[k]),
                .read_enable(read_enable),
                .write_enable(write_enable),
                .BL1out(BL1out[k])
            );
        end
    endgenerate

    // Output the combined byte
    assign dataout = BL1out;

endmodule
