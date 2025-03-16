module fulladder (
    input  wire a,
    input  wire b,
    input  wire cin,//carry
    output wire sum,
    output wire cout
);
    wire axb;
    wire axbcin;
    wire ab;

    xor (axb, a, b);
    xor (sum, axb, cin);
    and (ab,   a, b);
    and (axbcin, axb, cin);
    or  (cout, ab, axbcin);

endmodule
