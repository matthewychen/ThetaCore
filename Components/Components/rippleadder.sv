module rippleadder (
    input  wire [31:0] A,
    input  wire [31:0] B,
    output wire [32:0] SUM
);

    wire [31:0] c; //carry array

    genvar i;
    generate
        for (i = 0; i < 32; i = i + 1) begin : FA_BITS
            if (i == 0) begin
                fulladder FA (
                    .a    (A[i]),
                    .b    (B[i]),
                    .cin  (1'b0),
                    .sum  (SUM[i]),
                    .cout (c[i])
                );
            end else begin
                fulladder FA (
                    .a    (A[i]),
                    .b    (B[i]),
                    .cin  (c[i-1]),
                    .sum  (SUM[i]),
                    .cout (c[i])
                );
            end
        end
    endgenerate

    assign SUM[32] = c[31];

endmodule
