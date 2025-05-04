module CU_IF(
    //templated
    input soc_clk,
    input IF_reset,
    input IF_stall,
    input memfetch_start,
    input [31:0] addr,
    input [3:0] bits_to_access,
    input read_or_write, //should always be read in IF
    //need to retrieve from and write data to SRAM.

    output [31:0] IF_data //instruction to CU
);

// need to edit and pass signals back upwards to interface with MMU


endmodule