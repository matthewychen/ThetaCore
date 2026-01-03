module SRAMcell(
    input  logic clk,
    input  logic wordline,
    input  logic BL1in,
    input  logic BL2in,
    input  logic read_enable,
    input  logic write_enable,
    output logic BL1out
);

    // Internal storage (cross-coupled inverters)
    reg I_main;
    reg I_bar;

    initial begin
        I_main = 1'b0;
        I_bar  = 1'b1;
    end

    // Write operation (synchronous)
    always @(posedge clk) begin
        if (wordline && write_enable) begin
            I_main <= BL1in;
            I_bar  <= BL2in;
        end
    end

    // Read operation (continuous output while enabled)
    assign BL1out = (wordline && read_enable) ? I_main : 1'bz;

endmodule
