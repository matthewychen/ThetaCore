module SRAddress(
    input WL;
    input [31:0] datain,
    output [31:0] dataout
);

reg [31:0] BL1in;
reg [31:0] BL2in;

reg [31:0] BL1out;
reg [31:0] BL2out;

assign BL1in = datain;
assign BL2in = ~BL1in;

Cell0 SRAMcell(.WL(WL), .BL1in(BL1in[0]), .BL2in(BL2in[0]), .BL1out(BL1out[0]), .BL2out(BL2out[0]));
Cell1 SRAMcell(.WL(WL), .BL1in(BL1in[1]), .BL2in(BL2in[1]), .BL1out(BL1out[1]), .BL2out(BL2out[1]));
Cell2 SRAMcell(.WL(WL), .BL1in(BL1in[2]), .BL2in(BL2in[2]), .BL1out(BL1out[2]), .BL2out(BL2out[2]));
Cell3 SRAMcell(.WL(WL), .BL1in(BL1in[3]), .BL2in(BL2in[3]), .BL1out(BL1out[3]), .BL2out(BL2out[3]));
Cell4 SRAMcell(.WL(WL), .BL1in(BL1in[4]), .BL2in(BL2in[4]), .BL1out(BL1out[4]), .BL2out(BL2out[4]));
Cell5 SRAMcell(.WL(WL), .BL1in(BL1in[5]), .BL2in(BL2in[5]), .BL1out(BL1out[5]), .BL2out(BL2out[5]));
Cell6 SRAMcell(.WL(WL), .BL1in(BL1in[6]), .BL2in(BL2in[6]), .BL1out(BL1out[6]), .BL2out(BL2out[6]));
Cell7 SRAMcell(.WL(WL), .BL1in(BL1in[7]), .BL2in(BL2in[7]), .BL1out(BL1out[7]), .BL2out(BL2out[7]));
Cell8 SRAMcell(.WL(WL), .BL1in(BL1in[8]), .BL2in(BL2in[8]), .BL1out(BL1out[8]), .BL2out(BL2out[8]));
Cell9 SRAMcell(.WL(WL), .BL1in(BL1in[9]), .BL2in(BL2in[9]), .BL1out(BL1out[9]), .BL2out(BL2out[9]));
Cell10 SRAMcell(.WL(WL), .BL1in(BL1in[10]), .BL2in(BL2in[10]), .BL1out(BL1out[10]), .BL2out(BL2out[10]));
Cell11 SRAMcell(.WL(WL), .BL1in(BL1in[11]), .BL2in(BL2in[11]), .BL1out(BL1out[11]), .BL2out(BL2out[11]));
Cell12 SRAMcell(.WL(WL), .BL1in(BL1in[12]), .BL2in(BL2in[12]), .BL1out(BL1out[12]), .BL2out(BL2out[12]));
Cell13 SRAMcell(.WL(WL), .BL1in(BL1in[13]), .BL2in(BL2in[13]), .BL1out(BL1out[13]), .BL2out(BL2out[13]));
Cell14 SRAMcell(.WL(WL), .BL1in(BL1in[14]), .BL2in(BL2in[14]), .BL1out(BL1out[14]), .BL2out(BL2out[14]));
Cell15 SRAMcell(.WL(WL), .BL1in(BL1in[15]), .BL2in(BL2in[15]), .BL1out(BL1out[15]), .BL2out(BL2out[15]));
Cell16 SRAMcell(.WL(WL), .BL1in(BL1in[16]), .BL2in(BL2in[16]), .BL1out(BL1out[16]), .BL2out(BL2out[16]));
Cell17 SRAMcell(.WL(WL), .BL1in(BL1in[17]), .BL2in(BL2in[17]), .BL1out(BL1out[17]), .BL2out(BL2out[17]));
Cell18 SRAMcell(.WL(WL), .BL1in(BL1in[18]), .BL2in(BL2in[18]), .BL1out(BL1out[18]), .BL2out(BL2out[18]));
Cell19 SRAMcell(.WL(WL), .BL1in(BL1in[19]), .BL2in(BL2in[19]), .BL1out(BL1out[19]), .BL2out(BL2out[19]));
Cell20 SRAMcell(.WL(WL), .BL1in(BL1in[20]), .BL2in(BL2in[20]), .BL1out(BL1out[20]), .BL2out(BL2out[20]));
Cell21 SRAMcell(.WL(WL), .BL1in(BL1in[21]), .BL2in(BL2in[21]), .BL1out(BL1out[21]), .BL2out(BL2out[21]));
Cell22 SRAMcell(.WL(WL), .BL1in(BL1in[22]), .BL2in(BL2in[22]), .BL1out(BL1out[22]), .BL2out(BL2out[22]));
Cell23 SRAMcell(.WL(WL), .BL1in(BL1in[23]), .BL2in(BL2in[23]), .BL1out(BL1out[23]), .BL2out(BL2out[23]));
Cell24 SRAMcell(.WL(WL), .BL1in(BL1in[24]), .BL2in(BL2in[24]), .BL1out(BL1out[24]), .BL2out(BL2out[24]));
Cell25 SRAMcell(.WL(WL), .BL1in(BL1in[25]), .BL2in(BL2in[25]), .BL1out(BL1out[25]), .BL2out(BL2out[25]));
Cell26 SRAMcell(.WL(WL), .BL1in(BL1in[26]), .BL2in(BL2in[26]), .BL1out(BL1out[26]), .BL2out(BL2out[26]));
Cell27 SRAMcell(.WL(WL), .BL1in(BL1in[27]), .BL2in(BL2in[27]), .BL1out(BL1out[27]), .BL2out(BL2out[27]));
Cell28 SRAMcell(.WL(WL), .BL1in(BL1in[28]), .BL2in(BL2in[28]), .BL1out(BL1out[28]), .BL2out(BL2out[28]));
Cell29 SRAMcell(.WL(WL), .BL1in(BL1in[29]), .BL2in(BL2in[29]), .BL1out(BL1out[29]), .BL2out(BL2out[29]));
Cell30 SRAMcell(.WL(WL), .BL1in(BL1in[30]), .BL2in(BL2in[30]), .BL1out(BL1out[30]), .BL2out(BL2out[30]));
Cell31 SRAMcell(.WL(WL), .BL1in(BL1in[31]), .BL2in(BL2in[31]), .BL1out(BL1out[31]), .BL2out(BL2out[31]));

endmodule