module CU_MEM(
    //copied from IF
    input soc_clk,
    input MEM_reset,
    input MEM_stall,
    input memfetch_start,
    input [31:0] addr,
    input [3:0] bits_to_access,
    input read_or_write, //should always be read in IF
    //need to retrieve from and write data to SRAM.
    
    output [31:0] MEM_data //instruction to CU
);

// need to edit and pass signals back upwards to interface with MMU

endmodule