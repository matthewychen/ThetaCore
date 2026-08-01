`include "cu_opcodes.vh"

//==============================================================================
// Program counter and next-PC selection.
//
// Holds PC, and owns the two adders that produce candidate next addresses.
// The JALR target arrives pre-computed from the ALU (rs1 + imm).
//==============================================================================

module pc_unit(
    input soc_clk,
    input reset,

    // In a multi-cycle machine the PC must hold for the whole instruction and
    // advance exactly once, at the end. Without this enable the PC would run
    // away at one address per clock while a single instruction was still
    // being decoded.
    input             PCWrite,
    input      [1:0]  PCSel,

    input      [31:0] pc_increment, // from IDU: 4 normally, the offset for JAL
    input      [31:0] imm,          // branch offset
    input      [31:0] alu_out,      // JALR target, rs1 + imm

    output reg [31:0] PC,
    output     [31:0] pc_plus_4     // return address for JAL / JALR
);

    // Sequential path. The IDU sets pc_increment to 4 for every instruction
    // except JAL, where it carries the jump offset -- so one adder serves both
    // "next instruction" and "take the jump". That overloading was already in
    // the IDU and it is a genuinely nice trick; keep it.
    wire [31:0] pc_seq    = PC + pc_increment;

    wire [31:0] pc_branch = PC + imm;

    // JALR must clear bit 0: rs1 + imm may be odd, but an instruction address
    // cannot be.
    wire [31:0] pc_jalr   = alu_out & ~32'd1;

    // Deliberately a separate constant adder rather than reusing pc_seq.
    // For JAL, pc_increment IS the jump offset, so pc_seq is the jump target,
    // not the return address. The link register must get PC + 4 regardless of
    // how far the jump goes.
    assign pc_plus_4 = PC + 32'd4;

    reg [31:0] pc_next;
    always @(*) begin
        case (PCSel)
            `PCSEL_BRANCH: pc_next = pc_branch;
            `PCSEL_JALR:   pc_next = pc_jalr;
            default:       pc_next = pc_seq;
        endcase
    end

    always @(posedge soc_clk or posedge reset) begin
        if (reset)        PC <= 32'b0;   // reset vector: programs start at 0
        else if (PCWrite) PC <= pc_next;
    end

endmodule
