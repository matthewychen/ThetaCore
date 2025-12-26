module xnor_gate(
    input A,
    input B,
    output O
)

wire xnor_temp;

xor_gate xor1(xnor_temp, A, B);
nor_gate not1(O, xnor_temp);

endmodule