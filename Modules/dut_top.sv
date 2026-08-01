`include "cu_opcodes.vh"

//==============================================================================
// Synthesisable top level.
//
// Everything below this is the core proper. This layer exists to be the thing
// handed to a synthesis tool or a board: a clock, a reset, and status out.
//
// The program image reaches SRAM_sim through the +PROG plusarg in simulation,
// or would come from a BRAM init file on real hardware. It is deliberately not
// threaded through here as a parameter -- the top level should not need to
// know how memory got its contents.
//==============================================================================

module dut_top(
    input  soc_clk,
    input  reset,

    // status
    output        halted,
    output        retire_pulse,  // one pulse per instruction completed
    output [31:0] pc_out
);

    wire [31:0] dbg_IR;
    wire [2:0]  dbg_state;

    CU_top core(
        .soc_clk   (soc_clk),
        .reset     (reset),
        .dbg_PC    (pc_out),
        .dbg_IR    (dbg_IR),
        .dbg_state (dbg_state),
        .dbg_retire(retire_pulse),
        .halted    (halted)
    );

endmodule
