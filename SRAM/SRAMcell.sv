//6T industry-standard SRAM latch
//needed to eliminate paired inverters for I and Ibar due to analog sim req
module SRAMcell(
    input logic WL,
    input logic BL1in,
    input logic BL2in,

    output logic BL1out,
    output logic BL2out //unused
);

reg I;
reg Ibar;

always @(*) begin
    if (WL) begin
        BL1out = I;
        BL2out = Ibar;
    end else begin
        BL1out = 1'bz;
        BL2out = 1'bz;
    end
end

always @(posedge WL) begin
    if(BL1in != 1'bz && BL2in !=1'bz) begin //no way to detect floating state without analog sim, use BMOD instead
        I <= BL1in;
        Ibar <= BL2in;
    end
end


endmodule