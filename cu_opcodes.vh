`ifndef CU_OPCODES_VH
`define CU_OPCODES_VH

//==============================================================================
// Single source of truth for the CU instruction encoding.
//
// This replaces the hand-maintained table in Modules/IDU/cu_code_ref.md.
// That file was documentation, not a contract: IDU_top and ALU_top each
// hardcoded the same 41 numbers independently, so they could drift apart
// with nothing to catch it.
//
// Every literal is explicitly sized. The bug this prevents: CU_top declared
// the opcode bus as [4:0], which caps at 31, so AND (36) silently truncated
// to 4 -- which is BEQ. A sized constant makes that a width error instead of
// a wrong-instruction-at-runtime.
//==============================================================================

// ---------- IDU -> CU opcode, 6 bits, range 0..40 ----------

// U type
`define CU_LUI      6'd0
`define CU_AUIPC    6'd1

// J type
`define CU_JAL      6'd2
`define CU_JALR     6'd3

// B type
`define CU_BEQ      6'd4
`define CU_BNE      6'd5
`define CU_BLT      6'd6
`define CU_BGE      6'd7
`define CU_BLTU     6'd8
`define CU_BGEU     6'd9

// S type (stores)
`define CU_SB       6'd10
`define CU_SH       6'd11
`define CU_SW       6'd12

// I type group 1 (loads)
`define CU_LB       6'd13
`define CU_LH       6'd14
`define CU_LW       6'd15
`define CU_LBU      6'd16
`define CU_LHU      6'd17

// I type group 2 (immediate ALU ops)
`define CU_ADDI     6'd18
`define CU_SLTI     6'd19
`define CU_SLTIU    6'd20
`define CU_XORI     6'd21
`define CU_ORI      6'd22
`define CU_ANDI     6'd23
`define CU_SLLI     6'd24
`define CU_SRLI     6'd25
`define CU_SRAI     6'd26

// R type
`define CU_ADD      6'd27
`define CU_SUB      6'd28
`define CU_SLL      6'd29
`define CU_SLT      6'd30
`define CU_SLTU     6'd31
`define CU_XOR      6'd32
`define CU_SRL      6'd33
`define CU_SRA      6'd34
`define CU_OR       6'd35
`define CU_AND      6'd36

// System / fence
`define CU_FENCE    6'd37
`define CU_FENCE_I  6'd38
`define CU_ECALL    6'd39
`define CU_EBREAK   6'd40

// ---------- IDU broad optype classification, internal to IDU_top ----------

`define OPT_LUI     4'd0
`define OPT_AUIPC   4'd1
`define OPT_JAL     4'd2
`define OPT_JALR    4'd3
`define OPT_B       4'd4
`define OPT_S       4'd5
`define OPT_LOAD    4'd6
`define OPT_ICALC   4'd7
`define OPT_R       4'd8
`define OPT_FENCE   4'd9
`define OPT_SYSTEM  4'd10
`define OPT_INVALID 4'd11
`define OPT_INITIAL 4'd12

// ---------- CU -> ALU operation select, 5 bits, range 0..16 ----------
//
// Deliberately a different, much smaller encoding than the CU opcode above:
// the ALU does not care whether an add came from ADD, ADDI, or a load
// address calculation.

`define ALUOP_BEQ   5'd0
`define ALUOP_BNE   5'd1
`define ALUOP_BLT   5'd2
`define ALUOP_BGE   5'd3
`define ALUOP_BLTU  5'd4
`define ALUOP_BGEU  5'd5
`define ALUOP_ADD   5'd6
`define ALUOP_SUB   5'd7
`define ALUOP_SLL   5'd8
`define ALUOP_SLT   5'd9
`define ALUOP_SLTU  5'd10
`define ALUOP_XOR   5'd11
`define ALUOP_SRL   5'd12
`define ALUOP_SRA   5'd13
`define ALUOP_OR    5'd14
`define ALUOP_AND   5'd15
`define ALUOP_NOP   5'd16

// ---------- datapath control signals ----------
//
// Named after the Berkeley RV32I datapath (PCSel / ASel / BSel / WBSel /
// MemRW / RegWEn) so this control table can be checked against any
// reference core.
//
// Two Berkeley signals are deliberately absent:
//   ImmSel  -- IDU_top generates imm internally and emits it directly.
//   BrUn/BrEq/BrLT -- our Comparator takes the specific branch opcode and
//                     emits "taken" (con_met) directly, rather than raw
//                     equal/less-than flags the control logic must combine.
//                     Strictly simpler than the reference.

// next PC source
`define PCSEL_SEQ     2'd0  // PC + pc_increment (covers sequential and JAL)
`define PCSEL_BRANCH  2'd1  // PC + imm, taken branch
`define PCSEL_JALR    2'd2  // (rs1 + imm) & ~1, from the ALU

// ALU operand a
`define ASEL_RS1      2'd0
`define ASEL_PC       2'd1  // AUIPC
`define ASEL_ZERO     2'd2  // LUI

// ALU operand b
`define BSEL_RS2      2'd0
`define BSEL_IMM      2'd1
`define BSEL_SHAMT    2'd2  // SLLI/SRLI/SRAI carry the count in shamt, not imm

// register write-back source
`define WBSEL_ALU     2'd0
`define WBSEL_MEM     2'd1  // loads
`define WBSEL_PC4     2'd2  // JAL/JALR return address

// memory direction, matches MMU read_or_write
`define MEMRW_READ    1'b0
`define MEMRW_WRITE   1'b1

`endif
