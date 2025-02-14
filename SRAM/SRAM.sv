module SRAM(
    input [7:0] addr,
    input retrieve_clk,

    input [31:0] datain,
    output [31:0] dataout,

    output f_ready
);

reg [127:0] WL_sel;

//need to implement MUX

initial begin
    WL_sel <= supply1;
end

always@(posedge retrieve_clk) begin
    reg [127:0] WL_sel_mask;
    if(addr[6])
        WL_sel_mask <= WL_sel_mask & 128'hFFFFFFFFFFFFFFFF0000000000000000;
    else
       WL_sel_mask <= WL_sel_mask & ~128'hFFFFFFFFFFFFFFFF0000000000000000;
    
    if(addr[5])
        WL_sel_mask = WL_sel_mask & 128'hFFFFFFFF00000000FFFFFFFF00000000;
    else
        WL_sel_mask = WL_sel_mask & ~128'hFFFFFFFF00000000FFFFFFFF00000000;
    if(addr[4])
        WL_sel_mask = WL_sel_mask & 128'hFFFF0000FFFF0000FFFF0000FFFF0000;
    else
        WL_sel_mask = WL_sel_mask & ~128'hFFFF0000FFFF0000FFFF0000FFFF0000;
    if(addr[3])
        WL_sel_mask = WL_sel_mask & 128'hFF00FF00FF00FF00FF00FF00FF00FF00;
    else
        WL_sel_mask = WL_sel_mask & ~128'hFF00FF00FF00FF00FF00FF00FF00FF00;
    if(addr[2])
        WL_sel_mask = WL_sel_mask & 128'hF0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0;
    else
        WL_sel_mask = WL_sel_mask & ~128'hF0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0;
    if(addr[1])
        WL_sel_mask = WL_sel_mask & 128'hCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC;
    else
        WL_sel_mask = WL_sel_mask & ~128'hCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC;
    if(addr[0])
        WL_sel_mask = WL_sel_mask & 128'hAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA;
    else
        WL_sel_mask = WL_sel_mask & ~128'hAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA;
    
    WL_sel <= WL_sel_mask; //set address to live
end

always@(negedge retrieve_clk) begin
    WL_sel <= supply1;
end

genvar i;
generate
    for (i = 0; i < 128; i = i + 1) begin : SRAM_addrs
        SRAddress SRAddress_inst(
            .WL(WL_sel[i]),
            .datain(datain),
            .dataout(datain)
        );
    end
endgenerate

endmodule