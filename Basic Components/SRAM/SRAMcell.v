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
    if(WL) begin
        if(BL1in != 1'bz and BL2in !=1'bz) begin
            I <= BL1in;
            Ibar <= BL2in;
        end
    end
end


endmodule