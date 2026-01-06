module MMU(
    input soc_clk,

    // FROM CU
    input [31:0] CU_address,   // byte address
    input [3:0]  CU_bytesel,   // byte enables
    input [31:0] CU_dat_in,
    input        read_or_write, // 0 = read, 1 = write
    input        retrieve,      // start memory op (pulse)

    // TO CU
    output reg [31:0] MMU_dat_out,
);

    // --------------------------------------------
    // Internal SRAM signals
    // --------------------------------------------
    reg  [6:0]  SRAM_addr_sel;
    reg         read_pulse;
    reg         write_pulse;

    // --------------------------------------------
    // SRAM instance
    // --------------------------------------------
    SRAM_sim sram_inst (
        .addr_sel   (CU_address),
        .byte_sel   (CU_bytesel),
        .read_pulse (read_pulse),
        .write_pulse(write_pulse),
        .datain     (SRAM_dat_in),
        .dataout    (MMU_dat_out)
    );

    // --------------------------------------------
    // MMU control FSM (stub for now)
    // --------------------------------------------
    always @(posedge soc_clk) begin
        SRAM_dat_in <= CU_dat_in;
        if(retrieve) begin
            if(read_or_write) begin //write
                write_pulse <= 1;
                read_pulse <= 0;
            end
            else begin //read
                write_pulse <= 0;
                read_pulse <= 1;
            end
        end
        else begin
            write_pulse <= 0;
            read_pulse <= 0;
        end
    end

endmodule
