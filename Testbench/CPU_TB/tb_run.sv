`timescale 1ns/1ps

//==============================================================================
// Generic program runner.
//
//   vvp runsim +PROG=programs/arith.hex
//
// Loads whatever +PROG names (SRAM_sim does the $readmemh), runs to halt, then
// dumps final architectural state in a machine-readable form so an external
// reference model can diff against it.
//==============================================================================

module tb_run;

    reg         soc_clk, reset;
    wire        halted, retire_pulse;
    wire [31:0] pc_out;

    integer cycles = 0;
    integer retired = 0;
    integer i;
    integer maxcyc;

    dut_top DUT (
        .soc_clk     (soc_clk),
        .reset       (reset),
        .halted      (halted),
        .retire_pulse(retire_pulse),
        .pc_out      (pc_out)
    );

    initial begin
        soc_clk = 0;
        forever #5 soc_clk = ~soc_clk;
    end

    always @(posedge soc_clk)
        if (!reset && DUT.core.state == 3'd4) retired = retired + 1;

    initial begin
        if (!$value$plusargs("MAXCYC=%d", maxcyc)) maxcyc = 20000;
        if ($test$plusargs("WAVE")) begin
            $dumpfile("run_wave.vcd");
            $dumpvars(0, tb_run);
        end

        reset = 1;
        repeat (4) @(posedge soc_clk);
        reset = 0;

        while (!halted && cycles < maxcyc) begin
            @(posedge soc_clk);
            cycles = cycles + 1;
        end

        if (!halted)
            $display("TIMEOUT cycles=%0d pc=%0d state=%0d",
                     cycles, pc_out, DUT.core.state);
        else
            $display("HALT pc=%0d cycles=%0d retired=%0d",
                     pc_out, cycles, retired);

        for (i = 0; i < 32; i = i + 1)
            $display("x%0d=%08x", i, DUT.core.registers.regs[i]);

        for (i = 0; i < 128; i = i + 1)
            $display("m%0d=%08x", i, DUT.core.memory.sram_inst.memory[i]);

        $display("END");
        $finish;
    end

endmodule
