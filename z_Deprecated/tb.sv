`include "defines.vh"

module tb();
    initial begin
        #257;
        SRAM.read_pulse = 0;
        #1;
        SRAM.read_pulse = 1;
        #1;
        SRAM.read_pulse = 0;
    end

    SRAM SRAM_DUT(
        .addr(SRAM.addr), 
        .addr_ready(SRAM.addr_ready),
        .read_pulse(SRAM.read_pulse),
        .write_pulse(SRAM.write_pulse),
        .datain(SRAM.datain),
        .dataout(SRAM.dataout),
        .f_ready(SRAM.f_ready)
    );

endmodule