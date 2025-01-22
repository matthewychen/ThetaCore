module and_gate(
    input A,
    input B,
    output O
);

wire and_temp;

nand_gate nand1(.O(and_temp), .A(A), .B(B));
not_gate not1(.A(and_temp), .O(O));

endmodule