`timescale 1ns/1ns
module tb;
reg myreg;
initial begin
    $dumpfile("wave.vcd");
    $dumpvars(0, tb);
    //$dumpvars(0, "tb");
    $display("Compilation Success!");

    myreg = 1;
    #1;
    myreg = 0;
    #2;
    myreg = 1;
    #3;
end

endmodule