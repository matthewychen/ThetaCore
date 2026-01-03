`timescale 1ns/1ps

module tb_SRAM;

    // Parameters (keep consistent with SRAM)
    localparam ADDR_WIDTH = 7;
    localparam DATA_WIDTH = 32;

    // Signals (match DUT port names)
    logic clk;
    logic reset;
    logic [ADDR_WIDTH-1:0] addr_sel;
    logic [3:0] byte_sel;
    logic read_enable;
    logic write_enable;
    logic [DATA_WIDTH-1:0] datain;
    logic [DATA_WIDTH-1:0] dataout;

    // Instantiate SRAM (see: SRAM/SRAM.sv)
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

    // Clock
    initial clk = 0;
    always #5 clk = ~clk; // 100 MHz

    // VCD dump
    initial begin
        $dumpfile("sram_wave.vcd");
        $dumpvars(0, tb_SRAM);
    end

    // Helpers
    task automatic write_word(input logic [ADDR_WIDTH-1:0] a,
                              input logic [DATA_WIDTH-1:0] d,
                              input logic [3:0] be);
        begin
            // Align to clock: set signals before a posedge so SRAM latches them
            @(negedge clk);
            addr_sel   = a;
            datain     = d;
            byte_sel   = be;
            write_enable = 1;
            read_enable  = 0;
            // Wait two posedges: first posedge latches WL_sel, second performs write in SRAMcell
            @(posedge clk);
            @(posedge clk);
            write_enable = 0;
            // small settle
            @(negedge clk);
        end
    endtask

    task automatic read_word(input logic [ADDR_WIDTH-1:0] a,
                             input logic [DATA_WIDTH-1:0] expected);
        begin
            // Align to clock: set address and enable read
            @(negedge clk);
            addr_sel    = a;
            // Enable all bytes for read so non-selected bytes return stored values
            byte_sel    = 4'b1111;
            read_enable = 1;
            write_enable = 0;
            // Wait two posedges: first latches WL_sel, second allows SRAM cells to drive dataout
            @(posedge clk);
            @(posedge clk);
            // sample
            if (dataout !== expected) begin
                $display("ERROR: Read mismatch @ addr %0d: got 0x%08h expected 0x%08h", a, dataout, expected);
            end else begin
                $display("OK: addr %0d = 0x%08h", a, dataout);
            end
            read_enable = 0;
            // small settle
            @(negedge clk);
        end
    endtask

    // Byte-enable helper: compose byte mask for writes
    function logic [3:0] be_mask(input int bytes);
        logic [3:0] m;
        begin
            m = 4'b1111; // default full-word
            case (bytes)
                1: m = 4'b0001;
                2: m = 4'b0011;
                3: m = 4'b0111;
                4: m = 4'b1111;
                default: m = 4'b1111;
            endcase
            return m;
        end
    endfunction

    // Basic stimulus
    initial begin
        // init
        reset = 1;
        addr_sel = '0;
        byte_sel = 4'b1111;
        read_enable = 0;
        write_enable = 0;
        datain = '0;
        repeat (4) @(negedge clk);
        reset = 0;
        @(negedge clk);

        // Simple deterministic tests
        // Write distinct patterns and read back
        write_word(7'd0,  32'hDEADBEEF, be_mask(4));
        write_word(7'd1,  32'hCAFEBABE, be_mask(4));
        write_word(7'd2,  32'h01234567, be_mask(4));
        write_word(7'd3,  32'h89ABCDEF, be_mask(4));

        // Read and verify
        read_word(7'd0, 32'hDEADBEEF);
        read_word(7'd1, 32'hCAFEBABE);
        read_word(7'd2, 32'h01234567);
        read_word(7'd3, 32'h89ABCDEF);

        // Byte-enable partial writes
        // zero then write low byte only
        write_word(7'd10, 32'h00000000, be_mask(4));
        write_word(7'd10, 32'h000000AA, be_mask(1)); // write byte0
        read_word(7'd10, 32'h000000AA);

        // Mixed byte writes
        write_word(7'd11, 32'hFFFFFFFF, be_mask(4));
        // clear upper three bytes
        write_word(7'd11, 32'h00FFFFFF, 4'b0001); // only lowest byte enabled -> no change to upper
        // read back (expect lowest byte = 0xFF still, others 0xFF)
        read_word(7'd11, 32'hFFFFFFFF);


        $display("TB finished.");
        #100 $finish;
    end

endmodule
