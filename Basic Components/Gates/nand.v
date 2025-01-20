module nand(
    input A,
    input B,
    output O
);

wire NMOS_temp;
    
//PMOS in parallel
pmos (O, 1'b1, A);
pmos (O, 1'b1, B);

//NMOS in series to avoid floating result
nmos (NMOS_temp, 1'b0, A);
nmos (O, NMOS_temp, B);

endmodule