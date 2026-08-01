`timescale 1ns/1ps
`include "cu_opcodes.vh"

module tb_pc_unit;

    reg         soc_clk, reset, PCWrite;
    reg  [1:0]  PCSel;
    reg  [31:0] pc_increment, imm, alu_out;
    wire [31:0] PC, pc_plus_4;

    integer passed = 0;
    integer failed = 0;

    pc_unit DUT (
        .soc_clk     (soc_clk),
        .reset       (reset),
        .PCWrite     (PCWrite),
        .PCSel       (PCSel),
        .pc_increment(pc_increment),
        .imm         (imm),
        .alu_out     (alu_out),
        .PC          (PC),
        .pc_plus_4   (pc_plus_4)
    );

    initial begin
        soc_clk = 0;
        forever #5 soc_clk = ~soc_clk;
    end

    task step;
    begin
        @(negedge soc_clk);
        PCWrite = 1;
        @(posedge soc_clk);
        #1 PCWrite = 0;
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
        $dumpfile("pc_wave.vcd");
        $dumpvars(0, tb_pc_unit);

        reset = 1; PCWrite = 0; PCSel = `PCSEL_SEQ;
        pc_increment = 32'd4; imm = 0; alu_out = 0;
        @(posedge soc_clk); @(posedge soc_clk);
        reset = 0; #1;

        $display("=== pc_unit verification ===");

        chk("reset vector", PC, 32'd0);

        // the multi-cycle hold: a clock edge with PCWrite low must not advance
        @(posedge soc_clk); #1;
        chk("holds while PCWrite=0", PC, 32'd0);

        step; chk("sequential +4", PC, 32'd4);
        step; chk("sequential +4 again", PC, 32'd8);
        chk("pc_plus_4 tracks PC", pc_plus_4, 32'd12);

        // JAL: pc_increment carries the jump offset instead of 4.
        // pc_plus_4 must still be PC+4 -- the link register gets the return
        // address, not the jump target. This is the bug the separate constant
        // adder exists to prevent.
        pc_increment = 32'h100;
        chk("pc_plus_4 unaffected by JAL offset", pc_plus_4, 32'd12);
        step;
        chk("JAL jumps by pc_increment", PC, 32'h108);

        // taken branch
        pc_increment = 32'd4; imm = 32'h20; PCSel = `PCSEL_BRANCH;
        step; chk("branch taken, PC+imm", PC, 32'h128);

        // not-taken branch falls back to the sequential path
        PCSel = `PCSEL_SEQ;
        step; chk("branch not taken, PC+4", PC, 32'h12C);

        // negative branch offset, backwards jump
        imm = 32'hFFFFFFF8; PCSel = `PCSEL_BRANCH;   // -8
        step; chk("backwards branch", PC, 32'h124);

        // JALR must clear bit 0 of an odd target
        alu_out = 32'h201; PCSel = `PCSEL_JALR;
        step; chk("JALR clears bit 0", PC, 32'h200);

        // JALR with an already-even target is unchanged
        alu_out = 32'h340; PCSel = `PCSEL_JALR;
        step; chk("JALR even target", PC, 32'h340);

        $display("==================================");
        $display("Passed: %0d  Failed: %0d", passed, failed);
        $display("==================================");
        $finish;
    end

endmodule
