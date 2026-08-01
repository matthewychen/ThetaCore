`ifndef DISASM_VH
`define DISASM_VH

//==============================================================================
// RV32I disassembler for trace output.
//
// Simulation only -- include it inside a testbench module, never in RTL.
// Decodes straight from the instruction word, so it works on any program
// including the randomly generated ones from difftest.py, not just images
// the assembler happened to produce.
//==============================================================================

function string disasm(input [31:0] inst);
    reg [6:0] op, f7;
    reg [2:0] f3;
    reg [4:0] rd, rs1, rs2, shamt;
    integer   immi, imms, immb, immj;
    begin
        op    = inst[6:0];
        rd    = inst[11:7];
        f3    = inst[14:12];
        rs1   = inst[19:15];
        rs2   = inst[24:20];
        f7    = inst[31:25];
        shamt = inst[24:20];

        immi = $signed({{20{inst[31]}}, inst[31:20]});
        imms = $signed({{20{inst[31]}}, inst[31:25], inst[11:7]});
        immb = $signed({{19{inst[31]}}, inst[31], inst[7],
                        inst[30:25], inst[11:8], 1'b0});
        immj = $signed({{11{inst[31]}}, inst[31], inst[19:12],
                        inst[20], inst[30:21], 1'b0});

        case (op)

        7'b0110011:                                  // R-type
            case ({f7[5], f3})
            4'b0000: disasm = $sformatf("add    x%0d, x%0d, x%0d", rd, rs1, rs2);
            4'b1000: disasm = $sformatf("sub    x%0d, x%0d, x%0d", rd, rs1, rs2);
            4'b0001: disasm = $sformatf("sll    x%0d, x%0d, x%0d", rd, rs1, rs2);
            4'b0010: disasm = $sformatf("slt    x%0d, x%0d, x%0d", rd, rs1, rs2);
            4'b0011: disasm = $sformatf("sltu   x%0d, x%0d, x%0d", rd, rs1, rs2);
            4'b0100: disasm = $sformatf("xor    x%0d, x%0d, x%0d", rd, rs1, rs2);
            4'b0101: disasm = $sformatf("srl    x%0d, x%0d, x%0d", rd, rs1, rs2);
            4'b1101: disasm = $sformatf("sra    x%0d, x%0d, x%0d", rd, rs1, rs2);
            4'b0110: disasm = $sformatf("or     x%0d, x%0d, x%0d", rd, rs1, rs2);
            4'b0111: disasm = $sformatf("and    x%0d, x%0d, x%0d", rd, rs1, rs2);
            default: disasm = $sformatf("r?     %08x", inst);
            endcase

        7'b0010011:                                  // I-type ALU
            case (f3)
            3'b000: disasm = $sformatf("addi   x%0d, x%0d, %0d", rd, rs1, immi);
            3'b010: disasm = $sformatf("slti   x%0d, x%0d, %0d", rd, rs1, immi);
            3'b011: disasm = $sformatf("sltiu  x%0d, x%0d, %0d", rd, rs1, immi);
            3'b100: disasm = $sformatf("xori   x%0d, x%0d, %0d", rd, rs1, immi);
            3'b110: disasm = $sformatf("ori    x%0d, x%0d, %0d", rd, rs1, immi);
            3'b111: disasm = $sformatf("andi   x%0d, x%0d, %0d", rd, rs1, immi);
            3'b001: disasm = $sformatf("slli   x%0d, x%0d, %0d", rd, rs1, shamt);
            3'b101: disasm = f7[5]
                    ? $sformatf("srai   x%0d, x%0d, %0d", rd, rs1, shamt)
                    : $sformatf("srli   x%0d, x%0d, %0d", rd, rs1, shamt);
            default: disasm = $sformatf("i?     %08x", inst);
            endcase

        7'b0000011:                                  // loads
            case (f3)
            3'b000: disasm = $sformatf("lb     x%0d, %0d(x%0d)", rd, immi, rs1);
            3'b001: disasm = $sformatf("lh     x%0d, %0d(x%0d)", rd, immi, rs1);
            3'b010: disasm = $sformatf("lw     x%0d, %0d(x%0d)", rd, immi, rs1);
            3'b100: disasm = $sformatf("lbu    x%0d, %0d(x%0d)", rd, immi, rs1);
            3'b101: disasm = $sformatf("lhu    x%0d, %0d(x%0d)", rd, immi, rs1);
            default: disasm = $sformatf("l?     %08x", inst);
            endcase

        7'b0100011:                                  // stores
            case (f3)
            3'b000: disasm = $sformatf("sb     x%0d, %0d(x%0d)", rs2, imms, rs1);
            3'b001: disasm = $sformatf("sh     x%0d, %0d(x%0d)", rs2, imms, rs1);
            3'b010: disasm = $sformatf("sw     x%0d, %0d(x%0d)", rs2, imms, rs1);
            default: disasm = $sformatf("s?     %08x", inst);
            endcase

        7'b1100011:                                  // branches
            case (f3)
            3'b000: disasm = $sformatf("beq    x%0d, x%0d, %0d", rs1, rs2, immb);
            3'b001: disasm = $sformatf("bne    x%0d, x%0d, %0d", rs1, rs2, immb);
            3'b100: disasm = $sformatf("blt    x%0d, x%0d, %0d", rs1, rs2, immb);
            3'b101: disasm = $sformatf("bge    x%0d, x%0d, %0d", rs1, rs2, immb);
            3'b110: disasm = $sformatf("bltu   x%0d, x%0d, %0d", rs1, rs2, immb);
            3'b111: disasm = $sformatf("bgeu   x%0d, x%0d, %0d", rs1, rs2, immb);
            default: disasm = $sformatf("b?     %08x", inst);
            endcase

        7'b0110111: disasm = $sformatf("lui    x%0d, 0x%0h", rd, inst[31:12]);
        7'b0010111: disasm = $sformatf("auipc  x%0d, 0x%0h", rd, inst[31:12]);
        7'b1101111: disasm = $sformatf("jal    x%0d, %0d", rd, immj);
        7'b1100111: disasm = $sformatf("jalr   x%0d, %0d(x%0d)", rd, immi, rs1);

        7'b1110011: disasm = inst[20] ? "ebreak" : "ecall";
        7'b0001111: disasm = f3[0] ? "fence.i" : "fence";

        default: disasm = $sformatf("???    %08x", inst);
        endcase
    end
endfunction

`endif
