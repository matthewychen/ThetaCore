`timescale 1ns/1ps
`include "cu_opcodes.vh"

module tb_mmu;

    reg         soc_clk, reset;
    reg  [31:0] CU_address, CU_dat_in;
    reg  [1:0]  CU_width;
    reg         CU_signed, read_or_write, retrieve;
    wire        MMU_ready;
    wire [31:0] MMU_dat_out;

    integer passed = 0;
    integer failed = 0;

    MMU DUT (
        .soc_clk      (soc_clk),
        .reset        (reset),
        .CU_address   (CU_address),
        .CU_width     (CU_width),
        .CU_signed    (CU_signed),
        .CU_dat_in    (CU_dat_in),
        .read_or_write(read_or_write),
        .retrieve     (retrieve),
        .MMU_ready    (MMU_ready),
        .MMU_dat_out  (MMU_dat_out)
    );

    initial begin
        soc_clk = 0;
        forever #5 soc_clk = ~soc_clk;
    end

    // An access runs IDLE -> ACCESS -> CAPTURE -> DONE, so four edges from
    // the one that consumes retrieve.
    task access(input [31:0] a, input [1:0] w, input sgn, input rw, input [31:0] d);
    begin
        @(negedge soc_clk);
        CU_address = a; CU_width = w; CU_signed = sgn;
        read_or_write = rw; CU_dat_in = d; retrieve = 1;
        @(posedge soc_clk);
        #1 retrieve = 0;
        @(posedge soc_clk);
        @(posedge soc_clk);
        #1;
    end
    endtask

    task st(input [31:0] a, input [1:0] w, input [31:0] d);
    begin
        access(a, w, 1'b0, `MEMRW_WRITE, d);
        @(posedge soc_clk); #1;
    end
    endtask

    task ld(input string name, input [31:0] a, input [1:0] w, input sgn,
            input [31:0] exp);
    begin
        access(a, w, sgn, `MEMRW_READ, 32'b0);
        if (MMU_dat_out === exp) begin
            $display("[PASS] %s = %h", name, MMU_dat_out);
            passed = passed + 1;
        end else begin
            $display("[FAIL] %s: expected %h, got %h", name, exp, MMU_dat_out);
            failed = failed + 1;
        end
        @(posedge soc_clk); #1;
    end
    endtask

    initial begin
        $dumpfile("mmu_wave.vcd");
        $dumpvars(0, tb_mmu);

        reset = 1; retrieve = 0; CU_address = 0; CU_width = `MEMW_WORD;
        CU_signed = 0; read_or_write = `MEMRW_READ; CU_dat_in = 0;
        @(posedge soc_clk); @(posedge soc_clk);
        reset = 0; #1;

        $display("=== MMU verification ===");

        // ---- word round trip ----
        st(32'h10, `MEMW_WORD, 32'hDEADBEEF);
        ld("lw  @0x10",       32'h10, `MEMW_WORD, 1'b0, 32'hDEADBEEF);

        // ---- byte lane select, little endian ----
        ld("lbu @0x10 (b0)",  32'h10, `MEMW_BYTE, 1'b0, 32'h000000EF);
        ld("lbu @0x11 (b1)",  32'h11, `MEMW_BYTE, 1'b0, 32'h000000BE);
        ld("lbu @0x12 (b2)",  32'h12, `MEMW_BYTE, 1'b0, 32'h000000AD);
        ld("lbu @0x13 (b3)",  32'h13, `MEMW_BYTE, 1'b0, 32'h000000DE);

        // ---- byte sign extension ----
        ld("lb  @0x10 signed", 32'h10, `MEMW_BYTE, 1'b1, 32'hFFFFFFEF);
        ld("lb  @0x13 signed", 32'h13, `MEMW_BYTE, 1'b1, 32'hFFFFFFDE);

        // ---- halfword lane select and extension ----
        ld("lhu @0x10",        32'h10, `MEMW_HALF, 1'b0, 32'h0000BEEF);
        ld("lhu @0x12",        32'h12, `MEMW_HALF, 1'b0, 32'h0000DEAD);
        ld("lh  @0x10 signed", 32'h10, `MEMW_HALF, 1'b1, 32'hFFFFBEEF);
        ld("lh  @0x12 signed", 32'h12, `MEMW_HALF, 1'b1, 32'hFFFFDEAD);

        // ---- partial stores must not disturb neighbours ----
        st(32'h20, `MEMW_WORD, 32'h00000000);
        st(32'h21, `MEMW_BYTE, 32'h0000005A);
        ld("sb @0x21 lands in b1", 32'h20, `MEMW_WORD, 1'b0, 32'h00005A00);
        st(32'h23, `MEMW_BYTE, 32'h00000077);
        ld("sb @0x23 keeps b1",    32'h20, `MEMW_WORD, 1'b0, 32'h77005A00);
        ld("lbu @0x21 reads back", 32'h21, `MEMW_BYTE, 1'b0, 32'h0000005A);

        // ---- halfword stores at both alignments ----
        st(32'h30, `MEMW_WORD, 32'h00000000);
        st(32'h30, `MEMW_HALF, 32'h00001234);
        ld("sh @0x30 low half",    32'h30, `MEMW_WORD, 1'b0, 32'h00001234);
        st(32'h32, `MEMW_HALF, 32'h00008000);
        ld("sh @0x32 high half",   32'h30, `MEMW_WORD, 1'b0, 32'h80001234);
        ld("lh  @0x32 signed",     32'h32, `MEMW_HALF, 1'b1, 32'hFFFF8000);
        ld("lhu @0x32 unsigned",   32'h32, `MEMW_HALF, 1'b0, 32'h00008000);

        $display("==================================");
        $display("Passed: %0d  Failed: %0d", passed, failed);
        $display("==================================");
        $finish;
    end

endmodule
