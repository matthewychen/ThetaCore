module and (
    input A,
    input B,
    output O
);

wire temp;

nand nand(.O(temp), .A(A), .B(B));
not not(.O(O), .A(temp));

endmodule