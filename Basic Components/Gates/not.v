module not_gate(
    input A,
    output O
);

nmos(O, 1'b0, A);
pmos(O, 1'b1, A);

endmodule