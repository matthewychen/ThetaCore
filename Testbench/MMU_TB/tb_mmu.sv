`timescale 1ns/1ps

module tb_MMU;

    // Parameters
    localparam DATA_WIDTH = 32;

    // Signals
    logic clk;
    logic reset;
    
    // MMU Interface Signals
    logic [6:0] CU_address;
    logic [3:0]  CU_bytesel;
    logic [31:0] CU_dat_in;
    logic        read_or_write; // 0 = read, 1 = write
    logic        retrieve;      // start op pulse
    
    wire [31:0] MMU_dat_out;

    // Instantiate DUT
    MMU dut (
        .soc_clk(clk),
        .reset(reset),
        .CU_address(CU_address),
        .CU_bytesel(CU_bytesel),
        .CU_dat_in(CU_dat_in),
        .read_or_write(read_or_write),
        .retrieve(retrieve),
        .MMU_dat_out(MMU_dat_out)
    );

    // Clock Generation
    initial begin
        clk = 0;
        forever #5 clk = ~clk; // 100 MHz
    end

    // VCD Dump
    initial begin
        $dumpfile("mmu_wave.vcd");
        $dumpvars(0, tb_MMU);
    end

    // Helper Tasks
    task automatic write_word(
        input logic [6:0] addr,
        input logic [31:0] data, 
        input logic [3:0]  mask
    );
        begin
            @(posedge clk);
            CU_address = addr;
            CU_dat_in = data;
            CU_bytesel = mask;
            read_or_write = 1; // Write
            retrieve = 1;      // Start

            @(posedge clk);
            
            @(posedge clk);
            retrieve = 0;      // Pulse off
            
            // Allow time for internal SRAM pulse generation and write
            repeat(2) @(posedge clk);
        end
    endtask

    task automatic read_word(
        input logic [6:0] addr, 
        input logic [31:0] expected
    );
        begin
            @(posedge clk);
            CU_address = addr;
            CU_bytesel = 4'b1111; // Read full word
            read_or_write = 0;    // Read
            retrieve = 1;         // Start

            // Wait for data to propagate out
            repeat(2) @(posedge clk);

            if (MMU_dat_out !== expected) begin
                $display("ERROR  @ Addr %0h: Expected %h, Got %h", addr, expected, MMU_dat_out);
            end else begin
                $display("PASSED @ Addr %0h: Got %h", addr, MMU_dat_out);
            end
            retrieve = 0;
        end
    endtask

    // Main Test Sequence
    initial begin
        // Initialize Inputs
        CU_address = 0;
        CU_bytesel = 0;
        CU_dat_in = 0;
        read_or_write = 0;
        retrieve = 0;
        reset = 1;


        // Reset Wait
        repeat(5) @(posedge clk);
        reset = 0;
        #10;

        $display("=== Starting MMU Test ===");

        // 1. Basic Read/Write Test
        write_word(7'd0, 32'hDEADBEEF, 4'b1111);
        write_word(7'd1, 32'hCAFEBABE, 4'b1111);
        
        read_word(7'd0, 32'hDEADBEEF);
        read_word(7'd1, 32'hCAFEBABE);

        // 2. Byte Select Write Test
        // Write 0xFFFFFFFF
        write_word(7'd2, 32'hFFFFFFFF, 4'b1111);
        // Overwrite only lower byte with 0x00
        write_word(7'd2, 32'h00000000, 4'b0001);
        // Expect 0xFFFFFF00
        read_word(7'd2, 32'hFFFFFF00);

        // 3. Overlapping Regions Test
        // Write 0xAAAAAAAA to address 0
        write_word(7'd0, 32'hAAAAAAAA, 4'b1111);
        // Write 0x55555555 to address 2 (overlaps with previous)
        write_word(7'd2, 32'h55555555, 4'b1111);
        
        // Read back the overlapped region
        read_word(7'd0, 32'hAAAAAAAA);
        read_word(7'd2, 32'h55555555);

        // 4. Sequential Access Test
        // Write sequential words
        for (int i = 0; i < 4; i++) begin
            write_word(32'd10 + i, 32'hA5A5A5A5, 4'b1111);
        end
        
        // Read them back
        for (int i = 0; i < 4; i++) begin
            read_word(32'd10 + i, 32'hA5A5A5A5);
        end

        $display("=== MMU Test Completed ===");
        $finish;
    end

endmodule