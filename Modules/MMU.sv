module MMU(
    input soc_clk,
    input reset,

    // FROM CU
    input [31:0] CU_address,   // byte address
    input [3:0]  CU_bytesel,   // byte enables
    input [31:0] CU_dat_in,
    input        read_or_write, // 0 = read, 1 = write
    input        retrieve,      // start memory op (pulse)

    // TO CU
    output [31:0] MMU_dat_out
);

    // --------------------------------------------
    // Internal SRAM signals
    // --------------------------------------------
    reg  [31:0] SRAM_dat_in;
    reg         read_pulse;
    reg         write_pulse;

    // SRAM_sim is word addressed, CU_address is a byte address.
    // 128 words x 4 bytes each, so the word index is CU_address[8:2].
    wire [6:0]  SRAM_addr_sel = CU_address[8:2];

    // --------------------------------------------
    // SRAM instance
    // --------------------------------------------
    SRAM_sim sram_inst (
        .clk         (soc_clk),
        .reset       (reset),
        .addr_sel    (SRAM_addr_sel),
        .byte_sel    (CU_bytesel),
        .read_enable (read_pulse),
        .write_enable(write_pulse),
        .datain      (SRAM_dat_in),
        .dataout     (MMU_dat_out)
    );

    // --------------------------------------------
    // MMU control FSM (stub for now)
    // B6 adds load byte-lane select / sign-extension and store byte rotation.
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
