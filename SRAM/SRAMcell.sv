//6T industry-standard SRAM latch
//needed to eliminate paired inverters for I and Ibar due to analog sim req
module SRAMcell(
    input logic WL,
    input logic BL1in,
    input logic BL2in,

    input read_pulse,
    input write_pulse,

    output logic BL1out,
    output logic BL2out
);

reg I_main;
reg I_bar;

initial begin
    I_main = 1'b0;
    I_bar = 1'b1;
end

// Read operation - use different approach
reg read_active = 0;

// Detect read activation
always @(posedge read_pulse) begin
    read_active <= 1;
end

// Detect read deactivation
always @(negedge read_pulse) begin
    read_active <= 0;
    BL1out <= 1'bz;
    BL2out <= 1'bz;
end

// Continuous read output while read is active
always @(*) begin
    if (read_active && WL) begin
        BL1out = I_main;
        BL2out = I_bar;
    end else begin
        BL1out = 1'bz;
        BL2out = 1'bz;
    end
end

// Write operation
always @(negedge write_pulse) begin
    if (WL) begin
        I_main <= BL1in;
        I_bar <= BL2in;
    end
end

// Cross-coupled inverter behavior
// Only apply when not in a write operation
always @(*) begin
    if (!write_pulse) begin
        if (!WL || (WL && !read_pulse)) begin
            I_main = ~I_bar;
            I_bar = ~I_main;
        end
    end
end

endmodule