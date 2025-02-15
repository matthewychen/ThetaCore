`include "defines.vh"

module tb_top;

    SRAM_itf SRAM(); //interface instantiation

    //DUMP
    initial begin
        $dumpfile("wave.vcd");
        $dumpvars(0, tb_top);
        $display("Compilation Success!");
    end

    //TB MODULES//

    load_SRAM LSRAM();
    tb mytb();

endmodule
