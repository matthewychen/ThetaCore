//6T industry-standard SRAM latch
module SRAMcell(
    input WL,
    input BL1in,
    input BL2in,

    output reg BL1out,
    output reg BL2out
);

reg I;
reg Ibar;

assign BL1out = (WL) ? I : 1'bz; //indeterminate output when WL not active
assign BL2out = (WL) ? Ibar : 1'bz;

always @(*) begin
    if(WL == 1'b1) begin
        I <= BL1in;
        Ibar <= BL2in;
    end
end


endmodule