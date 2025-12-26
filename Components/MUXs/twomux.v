module twomux(
    input A,
    input B,
    input control,
    output O
);

wire Apath;
wire Bpath;
wire notcontrol;

assign notcontrol = ~control;
assign Apath = A & control;
assign Bpath = B & notcontrol;
assign O = Apath | Bpath;

endmodule