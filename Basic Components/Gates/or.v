module or_gate(
    input A,
    input B,
    input O
)

wire or_temp;

or_gate or1(or_temp, A, B);
not_gate not1(O, or_temp);

endmodule