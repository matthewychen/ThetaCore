//interface between the CPU and SRAM
//translates CU commands into byte addresses and retrieves from/stores in SRAM

module MMU(
    //in from CPU
    input [6:0] CU_address;
    input [31:0] CU_offset
    input [31:0] CU_dat_in;
    input mem_op;
    //1'b0 ---> read
    //1'b1 ---> write
    input start; //on posedge begin query

    //out to CPU
    output [31:0] CU_dat_out;
    //flags
    output flg_complete;

    //in from SRAM
    input [31:0] SRAM_dat_out;

    //out to SRAM
    output [6:0] SRAM_addr_sel;
    output [3:0] SRAM_byte_sel;
    input read_pulse,
    input write_pulse,
    input [31:0] SRAM_dat_in;
);

//goals:
// given offset from CU convert to address and byte address
// read/write pulse generation to SRAM
// process datawidth if nessessary, make sure that data if <32b are stored in MSB and logicalshift right.
// flag when complete


endmodule