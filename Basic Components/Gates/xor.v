module xor_gate(
    input A,
    input B,
    output O
);

wire b1;
wire NotA;
wire NotB;

//create inverters
not_gate not1(.A(A), .O(NotA));
not_gate not2(.A(B), .O(NotB));

//logic

//branch 1 = 01
pmos(b1, 1'b1, NotA);
pmos(O, b1, B);

//branch 2 - 10
wire b2;

pmos(b2, 1'b1, NotB);
pmos(O, b2, A);

//branch 3 - 11
wire b3;

nmos(b3, 1'b0, A);
nmos(O, b3, B);

//branch 4 - 00
wire b4;

nmos(b4, 1'b0, NotA);
nmos(O, b4, NotB);

endmodule