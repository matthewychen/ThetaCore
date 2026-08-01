`timescale 1ns/1ps

//==============================================================================
// End-to-end core test. Loads programs into the SRAM through a hierarchical
// reference, runs each to ECALL, then inspects the architectural state.
//==============================================================================

module tb_cpu;

`include "disasm.vh"

    reg         soc_clk, reset;
    wire [31:0] dbg_PC, dbg_IR;
    wire [2:0]  dbg_state;
    wire        dbg_retire, halted;

    integer passed = 0;
    integer failed = 0;
    integer cycles = 0;
    integer retired = 0;

    CU_top DUT (
        .soc_clk   (soc_clk),
        .reset     (reset),
        .dbg_PC    (dbg_PC),
        .dbg_IR    (dbg_IR),
        .dbg_state (dbg_state),
        .dbg_retire(dbg_retire),
        .halted    (halted)
    );

    initial begin
        soc_clk = 0;
        forever #5 soc_clk = ~soc_clk;
    end

    task chk(input string name, input [31:0] got, input [31:0] exp);
    begin
        if (got === exp) begin
            $display("[PASS] %-22s = %0d", name, got);
            passed = passed + 1;
        end else begin
            $display("[FAIL] %-22s expected %0d, got %0d", name, exp, got);
            failed = failed + 1;
        end
    end
    endtask

    always @(posedge soc_clk)
        if (!reset && dbg_state == 3'd4) retired = retired + 1;

    //--------------------------------------------------------------------------
    // Per-instruction register trace.  Enable with +TRACE:
    //     vvp testsim +TRACE
    // Off by default so the pass/fail output stays readable.
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
        else if (tr_on && dbg_state == 3'd4) begin
            // Read PC and IR before the edge settles: during WB they still
            // name the retiring instruction, not the next one.
            tr_pc = dbg_PC;
            tr_ir = dbg_IR;
            #1;                      // let the register write land
            tr_hit = 1'b0;
            for (ti = 0; ti < 32; ti = ti + 1) begin
                if (DUT.registers.regs[ti] !== prev_regs[ti]) begin
                    $display("TRACE %04x  %08x  %-22s  x%0d: %08x -> %08x",
                             tr_pc, tr_ir, disasm(tr_ir), ti,
                             prev_regs[ti], DUT.registers.regs[ti]);
                    prev_regs[ti] = DUT.registers.regs[ti];
                    tr_hit = 1'b1;
                end
            end
            if (!tr_hit)
                $display("TRACE %04x  %08x  %-22s  -",
                         tr_pc, tr_ir, disasm(tr_ir));
        end
    end

    task run_to_halt;
    begin
        cycles = 0; retired = 0;
        reset = 0;
        while (!halted && cycles < 4000) begin
            @(posedge soc_clk);
            cycles = cycles + 1;
        end
        if (!halted) begin
            $display("[FAIL] never halted after %0d cycles (state=%0d PC=%0d)",
                     cycles, dbg_state, dbg_PC);
            failed = failed + 1;
        end else
            $display("halted: %0d cycles, %0d retired, CPI ~%0d",
                     cycles, retired, cycles / retired);
    end
    endtask

    initial begin
        $dumpfile("cpu_wave.vcd");
        $dumpvars(0, tb_cpu);

        reset = 1;
        #1;   // let SRAM_sim's zeroing initial block settle first

        //----------------------------------------------------------------------
        // Program 1: arithmetic, store, load
        //----------------------------------------------------------------------
        DUT.memory.sram_inst.memory[0] = 32'h00500093; // addi x1, x0, 5
        DUT.memory.sram_inst.memory[1] = 32'h00700113; // addi x2, x0, 7
        DUT.memory.sram_inst.memory[2] = 32'h002081B3; // add  x3, x1, x2
        DUT.memory.sram_inst.memory[3] = 32'h40110233; // sub  x4, x2, x1
        DUT.memory.sram_inst.memory[4] = 32'h04302023; // sw   x3, 64(x0)
        DUT.memory.sram_inst.memory[5] = 32'h04002283; // lw   x5, 64(x0)
        DUT.memory.sram_inst.memory[6] = 32'h00000073; // ecall

        repeat (4) @(posedge soc_clk);
        $display("=== program 1: arithmetic and memory ===");
        run_to_halt;

        chk("x1 = addi 5",     DUT.registers.regs[1], 32'd5);
        chk("x2 = addi 7",     DUT.registers.regs[2], 32'd7);
        chk("x3 = add x1+x2",  DUT.registers.regs[3], 32'd12);
        chk("x4 = sub x2-x1",  DUT.registers.regs[4], 32'd2);
        chk("x5 = lw back",    DUT.registers.regs[5], 32'd12);
        chk("mem[64] = sw x3", DUT.memory.sram_inst.memory[16], 32'd12);
        chk("x0 still zero",   DUT.registers.regs[0], 32'd0);
        chk("PC halted at 24", dbg_PC, 32'd24);

        //----------------------------------------------------------------------
        // Program 2: control flow. A not-taken branch, a taken branch, and a
        // jump with link -- none of which program 1 exercised.
        //----------------------------------------------------------------------
        reset = 1;
        repeat (4) @(posedge soc_clk);
        #1;
        DUT.memory.sram_inst.memory[0] = 32'h00500093; // addi x1, x0, 5
        DUT.memory.sram_inst.memory[1] = 32'h00500113; // addi x2, x0, 5
        DUT.memory.sram_inst.memory[2] = 32'h00209663; // bne  x1, x2, +12  NOT taken
        DUT.memory.sram_inst.memory[3] = 32'h00100193; // addi x3, x0, 1    runs
        DUT.memory.sram_inst.memory[4] = 32'h00208463; // beq  x1, x2, +8   taken -> 0x18
        DUT.memory.sram_inst.memory[5] = 32'h06300213; // addi x4, x0, 99   skipped
        DUT.memory.sram_inst.memory[6] = 32'h008002EF; // jal  x5, +8       -> 0x20
        DUT.memory.sram_inst.memory[7] = 32'h04D00313; // addi x6, x0, 77   skipped
        DUT.memory.sram_inst.memory[8] = 32'h00000073; // ecall
        repeat (2) @(posedge soc_clk);

        $display("");
        $display("=== program 2: control flow ===");
        run_to_halt;

        chk("x1 = 5",             DUT.registers.regs[1], 32'd5);
        chk("x2 = 5",             DUT.registers.regs[2], 32'd5);
        chk("bne not taken",      DUT.registers.regs[3], 32'd1);
        chk("beq taken, skipped", DUT.registers.regs[4], 32'd0);
        chk("jal link = PC+4",    DUT.registers.regs[5], 32'd28);
        chk("jal target skipped", DUT.registers.regs[6], 32'd0);
        chk("PC halted at 32",    dbg_PC, 32'd32);

        $display("==================================");
        $display("Passed: %0d  Failed: %0d", passed, failed);
        $display("==================================");
        $finish;
    end

endmodule
