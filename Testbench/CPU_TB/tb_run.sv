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

`include "disasm.vh"

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

    //--------------------------------------------------------------------------
    // Per-instruction register trace.  Enable with +TRACE:
    //     vvp runsim +PROG=../programs/arith.hex +TRACE
    //
    // Off by default because difftest.py parses this testbench's stdout, and
    // 360 runs of trace output is a lot of noise for no benefit. Lines are
    // prefixed TRACE so they can never collide with the state dump either way.
    //--------------------------------------------------------------------------
    reg [31:0] prev_regs [0:31];
    reg [31:0] tr_pc, tr_ir;
    reg        tr_on, tr_hit;
    integer    ti;

    initial begin
        tr_on = $test$plusargs("TRACE");
        for (ti = 0; ti < 32; ti = ti + 1) prev_regs[ti] = 32'b0;
    end

    always @(posedge soc_clk) begin
        if (reset) begin
            for (ti = 0; ti < 32; ti = ti + 1) prev_regs[ti] = 32'b0;
        end
        else if (tr_on && DUT.core.state == 3'd4) begin
            // Read PC and IR before the edge settles: during WB they still
            // name the retiring instruction, not the next one.
            tr_pc = DUT.core.PC;
            tr_ir = DUT.core.Cu_IR;
            #1;                      // let the register write land
            tr_hit = 1'b0;
            for (ti = 0; ti < 32; ti = ti + 1) begin
                if (DUT.core.registers.regs[ti] !== prev_regs[ti]) begin
                    $display("TRACE %04x  %08x  %-22s  x%0d: %08x -> %08x",
                             tr_pc, tr_ir, disasm(tr_ir), ti,
                             prev_regs[ti], DUT.core.registers.regs[ti]);
                    prev_regs[ti] = DUT.core.registers.regs[ti];
                    tr_hit = 1'b1;
                end
            end
            if (!tr_hit)
                $display("TRACE %04x  %08x  %-22s  -",
                         tr_pc, tr_ir, disasm(tr_ir));
        end
    end

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
