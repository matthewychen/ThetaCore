`timescale 1ns/1ps

module tb_SRAM;

    // Parameters
    localparam ADDR_WIDTH = 7;
    localparam DATA_WIDTH = 32;

    // Signals
    logic clk;
    logic reset;
    logic [ADDR_WIDTH-1:0] addr_sel;
    logic [3:0] byte_sel;
    logic read_enable;
    logic write_enable;
    logic [DATA_WIDTH-1:0] datain;
    logic [DATA_WIDTH-1:0] dataout;

    // Instantiate SRAM
    SRAM dut (
        .clk(clk),
        .reset(reset),
        .addr_sel(addr_sel),
        .byte_sel(byte_sel),
        .read_enable(read_enable),
        .write_enable(write_enable),
        .datain(datain),
        .dataout(dataout)
    );

    // Clock generation
    initial clk = 0;
    always #5 clk = ~clk; // 100 MHz

    initial begin
        $dumpfile("sram_wave.vcd");
        $dumpvars(0, tb_SRAM);
    end

    // Test sequence
    initial begin
        // Initialize
        reset = 1;
        addr_sel = 0;
        byte_sel = 4'b1111;
        read_enable = 0;
        write_enable = 0;
        datain = {32{1'b1}};
        @(posedge clk);
        reset = 0;
        @(posedge clk);

        $display("=== SRAM Test Start ===");

        // --- Test 1: Write and read full word ---
        addr_sel = 7'd10;
        datain = {32{1'b1}};
        //datain = 32'hDEADBEEF;
        byte_sel = 4'b1111;
        write_enable = 1;
        @(posedge clk);
        write_enable = 0;

        // Read back
        read_enable = 1;
        @(posedge clk);
        if (dataout !== 32'hDEADBEEF) 
            $display("ERROR: Full word read failed: %h", dataout);
        else
            $display("PASS: Full word read/write OK");
        read_enable = 0;

        // --- Test 2: Byte-enable write ---
        addr_sel = 7'd10;
        datain = 32'h12345678;
        byte_sel = 4'b0011; // Only lower 2 bytes
        write_enable = 1;
        @(posedge clk);
        write_enable = 0;

        // Read back
        read_enable = 1;
        @(posedge clk);
        $display("Byte-enable read: %h (expected DEAD5678)", dataout);
        read_enable = 0;

        // --- Test 3: Multiple addresses ---
        // Write addr 5
        addr_sel = 7'd5;
        datain = 32'hA5A5A5A5;
        byte_sel = 4'b1111;
        write_enable = 1;
        @(posedge clk);
        write_enable = 0;

        // Write addr 7
        addr_sel = 7'd7;
        datain = 32'h5A5A5A5A;
        byte_sel = 4'b1111;
        write_enable = 1;
        @(posedge clk);
        write_enable = 0;

        // Read back addr 5
        addr_sel = 7'd5;
        read_enable = 1;
        @(posedge clk);
        if (dataout !== 32'hA5A5A5A5) $display("ERROR: Addr5 read failed: %h", dataout);
        else $display("PASS: Addr5 OK");
        read_enable = 0;

        // Read back addr 7
        addr_sel = 7'd7;
        read_enable = 1;
        @(posedge clk);
        if (dataout !== 32'h5A5A5A5A) $display("ERROR: Addr7 read failed: %h", dataout);
        else $display("PASS: Addr7 OK");
        read_enable = 0;

        $display("=== SRAM Test Complete ===");
        $finish;
    end

endmodule
