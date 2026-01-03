module MMU(
    input soc_clk,

    // FROM CU
    input [31:0] CU_address,   // byte address
    input [3:0]  CU_bytesel,   // byte enables
    input [31:0] CU_dat_in,
    input        read_or_write, // 0 = read, 1 = write
    input        retrieve,      // start memory op (pulse)

    // TO CU
    output reg [31:0] CU_dat_out,
    output reg        mmu_complete
);

    // --------------------------------------------
    // Internal SRAM signals
    // --------------------------------------------
    reg  [6:0]  SRAM_addr_sel;
    reg  [3:0]  SRAM_byte_sel;
    reg         read_pulse;
    reg         write_pulse;
    reg  [31:0] SRAM_dat_in;

    wire [31:0] SRAM_dat_out;
    wire        SRAM_complete;

    // --------------------------------------------
    // SRAM instance
    // --------------------------------------------
    SRAM sram_inst (
        .addr_sel   (SRAM_addr_sel),
        .byte_sel   (SRAM_byte_sel),
        .read_pulse (read_pulse),
        .write_pulse(write_pulse),
        .datain     (SRAM_dat_in),
        .dataout    (SRAM_dat_out),
        .flg_complete(SRAM_complete)
    );

    // --------------------------------------------
    // MMU control FSM (stub for now)
    // --------------------------------------------
    always @(posedge soc_clk) begin
        // to be implemented
    end

endmodule
