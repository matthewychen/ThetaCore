module SRAM(
    input  logic        clk,
    input  logic        reset,
    input  logic [6:0]  addr_sel,
    input  logic [3:0]  byte_sel,
    input  logic        read_enable,    // synchronous read enable
    input  logic        write_enable,   // synchronous write enable
    input  logic [31:0] datain,
    output logic [31:0] dataout
);

    // Wordline selection for each address
    logic [127:0] WL_sel;
    logic [3:0]  SRAMAddress_byte_sel;
    wire [31:0]  dataout_array [127:0];

    // Drive WL_sel and byte selection synchronously
    always @(posedge clk) begin
        if (reset) begin
            WL_sel <= 128'd0;
            SRAMAddress_byte_sel <= 4'd0;
            dataout <= 32'd0;
        end else begin
            WL_sel <= 128'd0;                 // clear all wordlines each cycle
            if (read_enable || write_enable) begin
                WL_sel[addr_sel] <= 1'b1;     // select the current address
                SRAMAddress_byte_sel <= byte_sel;
            end
        end
    end

    // Instantiate each 32-bit address
    genvar i;
    generate
        for (i = 0; i < 128; i = i + 1) begin : SRAM_addrs
            SRAMaddress SRAMaddress_inst(
                .clk(clk),
                .WL(WL_sel[i]),
                .byte_sel(SRAMAddress_byte_sel),
                .datain(datain),
                .dataout(dataout_array[i]),
                .read_enable(read_enable),
                .write_enable(write_enable)
            );
        end
    endgenerate

    // Output the selected address data
    always @(posedge clk) begin
        if (reset)
            dataout <= 32'd0;
        else if (read_enable)
            dataout <= dataout_array[addr_sel]; // register read output
    end


endmodule
