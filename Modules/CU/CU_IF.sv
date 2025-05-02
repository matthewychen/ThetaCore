module CU_IF(
    //templated
    input soc_clk,
    input IF_reset,
    input memfetch_start,
    input [31:0] addr,
    input [3:0] bits_to_access,
    input read_or_write,
    //need to retrieve from and write data to SRAM.
    output [31:0] Cu_IR //instruction
);

// need to send signals upward to communicate with MMU


endmodule