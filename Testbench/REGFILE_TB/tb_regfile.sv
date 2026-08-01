`timescale 1ns/1ps

module tb_regfile;

    reg         soc_clk, reset, RegWEn;
    reg  [4:0]  rs1_addr, rs2_addr, rd_addr;
    reg  [31:0] rd_data;
    wire [31:0] rs1_data, rs2_data;

    integer passed = 0;
    integer failed = 0;

    regfile DUT (
        .soc_clk (soc_clk),
        .reset   (reset),
        .rs1_addr(rs1_addr),
        .rs2_addr(rs2_addr),
        .rs1_data(rs1_data),
        .rs2_data(rs2_data),
        .RegWEn  (RegWEn),
        .rd_addr (rd_addr),
        .rd_data (rd_data)
    );

    initial begin
        soc_clk = 0;
        forever #5 soc_clk = ~soc_clk;
    end

    task wr(input [4:0] a, input [31:0] d);
    begin
        @(negedge soc_clk);
        RegWEn = 1; rd_addr = a; rd_data = d;
        @(posedge soc_clk);
        #1 RegWEn = 0;
    end
    endtask

    task chk(input string name, input [31:0] got, input [31:0] exp);
    begin
        if (got === exp) begin
            $display("[PASS] %s = %h", name, got);
            passed = passed + 1;
        end else begin
            $display("[FAIL] %s: expected %h, got %h", name, exp, got);
            failed = failed + 1;
        end
    end
    endtask

    initial begin
        $dumpfile("regfile_wave.vcd");
        $dumpvars(0, tb_regfile);

        reset = 1; RegWEn = 0;
        rs1_addr = 0; rs2_addr = 0; rd_addr = 0; rd_data = 0;
        @(posedge soc_clk); @(posedge soc_clk);
        reset = 0; #1;

        $display("=== regfile verification ===");

        rs1_addr = 5'd7; #1;
        chk("x7 zeroed by reset", rs1_data, 32'd0);

        wr(5'd1, 32'hDEADBEEF);
        rs1_addr = 5'd1; #1;
        chk("x1 write then read", rs1_data, 32'hDEADBEEF);

        wr(5'd2, 32'hCAFEBABE);
        rs1_addr = 5'd1; rs2_addr = 5'd2; #1;
        chk("port a reads x1", rs1_data, 32'hDEADBEEF);
        chk("port b reads x2", rs2_data, 32'hCAFEBABE);

        // x0 must absorb a write and still read as zero
        wr(5'd0, 32'hFFFFFFFF);
        rs1_addr = 5'd0; #1;
        chk("x0 rejects write", rs1_data, 32'd0);

        // a write with RegWEn low must not land
        @(negedge soc_clk);
        RegWEn = 0; rd_addr = 5'd1; rd_data = 32'h11111111;
        @(posedge soc_clk); #1;
        rs1_addr = 5'd1; #1;
        chk("RegWEn=0 blocks write", rs1_data, 32'hDEADBEEF);

        // both ports addressing the same register
        rs1_addr = 5'd2; rs2_addr = 5'd2; #1;
        chk("same reg, port a", rs1_data, 32'hCAFEBABE);
        chk("same reg, port b", rs2_data, 32'hCAFEBABE);

        wr(5'd31, 32'h5A5A5A5A);
        rs1_addr = 5'd31; #1;
        chk("x31 top of file", rs1_data, 32'h5A5A5A5A);

        // reads are combinational: a new address must resolve with no clock
        rs2_addr = 5'd1; #1;
        chk("combinational read", rs2_data, 32'hDEADBEEF);

        $display("==================================");
        $display("Passed: %0d  Failed: %0d", passed, failed);
        $display("==================================");
        $finish;
    end

endmodule
