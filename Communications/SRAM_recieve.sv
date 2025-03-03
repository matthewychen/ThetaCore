module mux3way (
    input  wire [1:0] sel,   // 2-bit select input
    input  wire       in0,   // Input 0
    input  wire       in1,   // Input 1
    input  wire       in2,   // Input 2
    output wire       out    // Output
);

    assign out = (sel == 2'b00) ? in0 :
                 (sel == 2'b01) ? in1 :
                 (sel == 2'b10) ? in2 : 1'b0;

endmodule