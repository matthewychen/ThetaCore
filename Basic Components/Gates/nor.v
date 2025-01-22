module nor_gate(
    input A,
    input B,
    output O
);

wire PMOS_temp;

pmos(PMOS_temp, 1'b1, A);
pmos(O, PMOS_temp, B);

nmos(O, 1'b0, A);
nmos(O, 1'b0, B);


endmodule