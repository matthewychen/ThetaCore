interface SRAM_itf;
    logic [6:0] addr;
    logic addr_ready;
    logic read_pulse;
    logic write_pulse;
    logic [31:0] datain;
    logic [31:0] dataout;
    logic f_ready;
endinterface