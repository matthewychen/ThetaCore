module CU_IF(
    //templated
    input soc_clk,
    input reset,
    input CU_ready,
    input [31:0] addr,
    input [3:0] bits_to_access,
    input read_or_write,
    //need to retrieve from and write data to SRAM.
    output [31:0] Cu_IR //instruction
);

endmodule