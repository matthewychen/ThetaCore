module SRAMcell(
    input  logic clk,
    input  logic WL,
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
        if (WL && write_enable) begin
            I_main <= BL1in;
            I_bar  <= BL2in;
        end
    end

    // Cross-coupled inverter stability (continuous)
    always @(*) begin
        if (!(WL && write_enable)) begin
            I_bar  = ~I_main;
            I_main = ~I_bar;
        end
    end

    // Read operation (continuous output while enabled)
    assign BL1out = (WL && read_enable) ? I_main : 1'bz;

endmodule
