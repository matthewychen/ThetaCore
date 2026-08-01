#!/usr/bin/env python3
"""
Independent RV32I reference model for ThetaCore.

Written from the ISA specification, NOT derived from the Verilog -- that
independence is the whole point. It exists so the RTL can be checked against
something that does not share the RTL's assumptions.

    python tools/rvmodel.py programs/arith.hex

Prints final architectural state in the same format as Testbench/CPU_TB/
tb_run.sv, so the two can be diffed directly.

Caveat worth stating plainly: this is a weaker oracle than spike, because the
same person wrote it and the RTL. It catches transcription and encoding errors
reliably; it would not catch a shared misreading of the spec.
"""

import re
import sys

MASK = 0xFFFFFFFF


def sext(v, bits):
    m = 1 << (bits - 1)
    return (v & (m - 1)) - (v & m)


def u32(v):
    return v & MASK


def s32(v):
    v &= MASK
    return v - (1 << 32) if v & 0x80000000 else v


class Model:
    def __init__(self, words=128):
        self.x = [0] * 32
        self.mem = [0] * words
        self.pc = 0
        self.halted = False
        self.retired = 0
        self.error = None

    # ---- memory: byte addressed, little endian, over a word array ----
    def rb(self, a):
        return (self.mem[(a >> 2) % len(self.mem)] >> (8 * (a & 3))) & 0xFF

    def rh(self, a):
        return self.rb(a) | (self.rb(a + 1) << 8)

    def rw(self, a):
        return self.mem[(a >> 2) % len(self.mem)]

    def wb(self, a, v):
        i = (a >> 2) % len(self.mem)
        sh = 8 * (a & 3)
        self.mem[i] = u32((self.mem[i] & ~(0xFF << sh)) | ((v & 0xFF) << sh))

    def wh(self, a, v):
        self.wb(a, v)
        self.wb(a + 1, v >> 8)

    def ww(self, a, v):
        self.mem[(a >> 2) % len(self.mem)] = u32(v)

    def setreg(self, r, v):
        if r:                      # x0 is hardwired
            self.x[r] = u32(v)

    def load_hex(self, path):
        i = 0
        with open(path) as f:
            for line in f:
                tok = re.split(r'//|#', line)[0].strip()
                if not tok:
                    continue
                for word in tok.split():
                    if i < len(self.mem):
                        self.mem[i] = int(word, 16)
                        i += 1
        return i

    # ---- execute one instruction ----
    def step(self):
        if (self.pc >> 2) >= len(self.mem):
            self.error = "pc out of range: %d" % self.pc
            self.halted = True
            return

        inst = self.mem[self.pc >> 2]
        op = inst & 0x7F
        rd = (inst >> 7) & 0x1F
        f3 = (inst >> 12) & 7
        rs1 = (inst >> 15) & 0x1F
        rs2 = (inst >> 20) & 0x1F
        f7 = (inst >> 25) & 0x7F
        a, b = self.x[rs1], self.x[rs2]
        npc = self.pc + 4

        if op == 0x33:                                  # R-type
            sa, sb, sh = s32(a), s32(b), b & 31
            if   f3 == 0: r = a - b if f7 == 0x20 else a + b
            elif f3 == 1: r = a << sh
            elif f3 == 2: r = 1 if sa < sb else 0
            elif f3 == 3: r = 1 if a < b else 0
            elif f3 == 4: r = a ^ b
            elif f3 == 5: r = (sa >> sh) if f7 == 0x20 else (a >> sh)
            elif f3 == 6: r = a | b
            else:         r = a & b
            self.setreg(rd, r)

        elif op == 0x13:                                # I-type ALU
            imm = sext(inst >> 20, 12)
            sa, sh = s32(a), (inst >> 20) & 31
            if   f3 == 0: r = a + imm
            elif f3 == 2: r = 1 if sa < imm else 0
            elif f3 == 3: r = 1 if a < u32(imm) else 0
            elif f3 == 4: r = a ^ u32(imm)
            elif f3 == 6: r = a | u32(imm)
            elif f3 == 7: r = a & u32(imm)
            elif f3 == 1: r = a << sh
            else:         r = (sa >> sh) if (inst >> 30) & 1 else (a >> sh)
            self.setreg(rd, r)

        elif op == 0x03:                                # loads
            addr = u32(a + sext(inst >> 20, 12))
            if   f3 == 0: v = sext(self.rb(addr), 8)
            elif f3 == 1: v = sext(self.rh(addr), 16)
            elif f3 == 2: v = self.rw(addr)
            elif f3 == 4: v = self.rb(addr)
            elif f3 == 5: v = self.rh(addr)
            else:
                self.error = "bad load funct3=%d at pc=%d" % (f3, self.pc)
                self.halted = True
                return
            self.setreg(rd, v)

        elif op == 0x23:                                # stores
            imm = sext(((inst >> 25) << 5) | ((inst >> 7) & 0x1F), 12)
            addr = u32(a + imm)
            if   f3 == 0: self.wb(addr, b)
            elif f3 == 1: self.wh(addr, b)
            elif f3 == 2: self.ww(addr, b)
            else:
                self.error = "bad store funct3=%d at pc=%d" % (f3, self.pc)
                self.halted = True
                return

        elif op == 0x63:                                # branches
            imm = sext((((inst >> 31) & 1) << 12) | (((inst >> 7) & 1) << 11) |
                       (((inst >> 25) & 0x3F) << 5) | (((inst >> 8) & 0xF) << 1), 13)
            sa, sb = s32(a), s32(b)
            taken = {0: a == b, 1: a != b, 4: sa < sb,
                     5: sa >= sb, 6: a < b, 7: a >= b}.get(f3)
            if taken is None:
                self.error = "bad branch funct3=%d at pc=%d" % (f3, self.pc)
                self.halted = True
                return
            if taken:
                npc = u32(self.pc + imm)

        elif op == 0x37:                                # lui
            self.setreg(rd, u32(inst & 0xFFFFF000))

        elif op == 0x17:                                # auipc
            self.setreg(rd, u32(self.pc + (inst & 0xFFFFF000)))

        elif op == 0x6F:                                # jal
            imm = sext((((inst >> 31) & 1) << 20) | (((inst >> 12) & 0xFF) << 12) |
                       (((inst >> 20) & 1) << 11) | (((inst >> 21) & 0x3FF) << 1), 21)
            self.setreg(rd, self.pc + 4)
            npc = u32(self.pc + imm)

        elif op == 0x67:                                # jalr
            imm = sext(inst >> 20, 12)
            target = u32((a + imm) & ~1)
            self.setreg(rd, self.pc + 4)
            npc = target

        elif op == 0x73:                                # ecall / ebreak
            self.halted = True

        elif op == 0x0F:                                # fence, a nop here
            pass

        else:
            self.error = "invalid opcode 0x%02x at pc=%d" % (op, self.pc)
            self.halted = True

        self.retired += 1
        # On halt the PC stays at the instruction that stopped the machine,
        # matching the RTL, which suppresses PCWrite in that case.
        if not self.halted:
            self.pc = u32(npc)

    def run(self, max_instr=20000):
        while not self.halted and self.retired < max_instr:
            self.step()
        return self.halted

    def dump(self):
        out = []
        if not self.halted:
            out.append("TIMEOUT pc=%d" % self.pc)
        else:
            out.append("HALT pc=%d retired=%d" % (self.pc, self.retired))
        for i in range(32):
            out.append("x%d=%08x" % (i, self.x[i]))
        for i in range(len(self.mem)):
            out.append("m%d=%08x" % (i, self.mem[i]))
        out.append("END")
        return out


def main():
    if len(sys.argv) < 2:
        print("usage: rvmodel.py <image.hex>", file=sys.stderr)
        return 2
    m = Model()
    m.load_hex(sys.argv[1])
    m.run()
    if m.error:
        print("model error: %s" % m.error, file=sys.stderr)
    print('\n'.join(m.dump()))
    return 0


if __name__ == "__main__":
    sys.exit(main())
