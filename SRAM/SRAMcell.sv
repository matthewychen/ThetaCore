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

always @(posedge read_pulse) begin
    if (WL) begin
        BL1out = I_main;
        BL2out = I_bar;
    end else begin
        BL1out = 1'bz;
        BL2out = 1'bz;
    end
end

always @(*) begin
    if(WL & write_pulse) begin
        I_main <= BL1in;
        I_bar <= BL2in;
    end
end


endmodule