module nor_gate(
    input A,
    input B,
    output O
);

wire NotA;
wire NotB;

//create inverters
not_gate not1(.A(A), .O(NotA));
not_gate not2(.A(B), .O(NotB));

wire b1;
pmos(b1, 1'b1, A);
pmos(O, b1, B);

wire b2;
nmos(b2, 1'b0, NotA);
nmos(O, b2, B);

wire b3;
nmos(b3, 1'b0, A);
nmos(O, b3, NotB);

wire b4;
  nmos(b4, 1'b0, A);
  nmos(O, b4, B);

endmodule