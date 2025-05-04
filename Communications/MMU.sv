//interface between the CPU and SRAM
//translates CU commands into byte addresses and retrieves from/stores in SRAM

module MMU(
    //TO CU
    input soc_clk,
    input MMU_stall,
    input MMU_flush,
    input [31:0] CU_address, //for compatability reasons, 32b. this is copied from PC.
    input [3:0] CU_bytesel, //for byte-addressability.
    input [31:0] CU_dat_in,
    input read_or_write,
    //1'b0 ---> read
    //1'b1 ---> write

    input retrieve, //start query. Start retrieval on posedge. May be driven either 2 times or 1 time per 4-stage cycle, depending on if a memory operation is needed in MEM.

    //out to CU
    output reg [31:0] CU_dat_out, //raw instruction from address
    output reg MMU_ready, //on successful completion of read or write

    //TO SRAM
    //in from SRAM
    input [31:0] SRAM_dat_out,

    //out to SRAM. Needs to pass through CU to tb_top and into SRAM.
    output reg [6:0] SRAM_addr_sel,
    output reg [3:0] SRAM_byte_sel,
    output read_pulse,
    output write_pulse,
    input reg [31:0] SRAM_dat_in
);

//goals:
// given offset from CU convert to address and byte address
// read/write pulse generation to SRAM
// process datawidth if nessessary, make sure that data if <32b are stored in MSB and logicalshift right.
// flag when complete

//note: use instruction-aligned address, so CU_address [31:2].


endmodule