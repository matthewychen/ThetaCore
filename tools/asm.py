#!/usr/bin/env python3
"""
Minimal RV32I assembler for ThetaCore.

Emits a $readmemh-compatible hex image, one 32-bit word per line.

    python tools/asm.py programs/arith.s -o programs/arith.hex
    vvp testsim +PROG=programs/arith.hex

Supports the full RV32I base integer set plus a handful of pseudo-instructions.
Labels, decimal/hex immediates, and offset(reg) addressing.
"""

import argparse
import re
import sys

# ---------------------------------------------------------------------------
# Registers
# ---------------------------------------------------------------------------
ABI = {
    'zero': 0, 'ra': 1, 'sp': 2, 'gp': 3, 'tp': 4,
    't0': 5, 't1': 6, 't2': 7, 's0': 8, 'fp': 8, 's1': 9,
    'a0': 10, 'a1': 11, 'a2': 12, 'a3': 13,
    'a4': 14, 'a5': 15, 'a6': 16, 'a7': 17,
    's2': 18, 's3': 19, 's4': 20, 's5': 21, 's6': 22, 's7': 23,
    's8': 24, 's9': 25, 's10': 26, 's11': 27,
    't3': 28, 't4': 29, 't5': 30, 't6': 31,
}
for _i in range(32):
    ABI['x%d' % _i] = _i

# ---------------------------------------------------------------------------
# Instruction tables
# ---------------------------------------------------------------------------
OP_R, OP_I, OP_LD, OP_ST = 0x33, 0x13, 0x03, 0x23
OP_BR, OP_LUI, OP_AUIPC = 0x63, 0x37, 0x17
OP_JAL, OP_JALR, OP_SYS, OP_FENCE = 0x6F, 0x67, 0x73, 0x0F

R_TYPE = {  # name: (funct7, funct3)
    'add': (0x00, 0x0), 'sub': (0x20, 0x0), 'sll': (0x00, 0x1),
    'slt': (0x00, 0x2), 'sltu': (0x00, 0x3), 'xor': (0x00, 0x4),
    'srl': (0x00, 0x5), 'sra': (0x20, 0x5), 'or': (0x00, 0x6),
    'and': (0x00, 0x7),
}
I_TYPE = {'addi': 0x0, 'slti': 0x2, 'sltiu': 0x3,
          'xori': 0x4, 'ori': 0x6, 'andi': 0x7}
SH_TYPE = {'slli': (0x00, 0x1), 'srli': (0x00, 0x5), 'srai': (0x20, 0x5)}
LOADS = {'lb': 0x0, 'lh': 0x1, 'lw': 0x2, 'lbu': 0x4, 'lhu': 0x5}
STORES = {'sb': 0x0, 'sh': 0x1, 'sw': 0x2}
BRANCHES = {'beq': 0x0, 'bne': 0x1, 'blt': 0x4,
            'bge': 0x5, 'bltu': 0x6, 'bgeu': 0x7}


class AsmError(Exception):
    pass


# ---------------------------------------------------------------------------
# Encoders. Field placement follows the RV32I spec directly.
# ---------------------------------------------------------------------------
def enc_r(f7, rs2, rs1, f3, rd, op):
    return (f7 << 25) | (rs2 << 20) | (rs1 << 15) | (f3 << 12) | (rd << 7) | op


def enc_i(imm, rs1, f3, rd, op):
    return ((imm & 0xFFF) << 20) | (rs1 << 15) | (f3 << 12) | (rd << 7) | op


def enc_s(imm, rs2, rs1, f3, op):
    return (((imm >> 5) & 0x7F) << 25) | (rs2 << 20) | (rs1 << 15) | \
           (f3 << 12) | ((imm & 0x1F) << 7) | op


def enc_b(imm, rs2, rs1, f3, op):
    # imm[12|10:5] rs2 rs1 f3 imm[4:1|11] opcode -- the scrambled one
    return (((imm >> 12) & 1) << 31) | (((imm >> 5) & 0x3F) << 25) | \
           (rs2 << 20) | (rs1 << 15) | (f3 << 12) | \
           (((imm >> 1) & 0xF) << 8) | (((imm >> 11) & 1) << 7) | op


def enc_u(imm, rd, op):
    return ((imm & 0xFFFFF) << 12) | (rd << 7) | op


def enc_j(imm, rd, op):
    # imm[20|10:1|11|19:12] rd opcode
    return (((imm >> 20) & 1) << 31) | (((imm >> 1) & 0x3FF) << 21) | \
           (((imm >> 11) & 1) << 20) | (((imm >> 12) & 0xFF) << 12) | \
           (rd << 7) | op


# ---------------------------------------------------------------------------
# Parsing helpers
# ---------------------------------------------------------------------------
def reg(tok, line):
    t = tok.strip().lower()
    if t not in ABI:
        raise AsmError("line %d: unknown register %r" % (line, tok))
    return ABI[t]


def imm(tok, labels, pc, line, rel=False):
    t = tok.strip()
    if t in labels:
        return labels[t] - pc if rel else labels[t]
    try:
        return int(t, 0)
    except ValueError:
        raise AsmError("line %d: bad immediate or unknown label %r" % (line, t))


MEMREF = re.compile(r'^\s*(-?\w+)\s*\(\s*(\w+)\s*\)\s*$')


def memref(tok, line):
    m = MEMREF.match(tok)
    if not m:
        raise AsmError("line %d: expected offset(reg), got %r" % (line, tok))
    return int(m.group(1), 0), reg(m.group(2), line)


def fits(val, bits, line, what):
    lo, hi = -(1 << (bits - 1)), (1 << (bits - 1)) - 1
    if not (lo <= val <= hi):
        raise AsmError("line %d: %s %d out of range [%d, %d]"
                       % (line, what, val, lo, hi))


# ---------------------------------------------------------------------------
# Assembler
# ---------------------------------------------------------------------------
def tokenize(src):
    """Yield (line_no, label_or_None, mnemonic_or_None, [operands])."""
    out = []
    for n, raw in enumerate(src.splitlines(), 1):
        text = raw.split('#')[0].split('//')[0].strip()
        if not text:
            continue
        label = None
        while ':' in text:
            head, text = text.split(':', 1)
            label = head.strip()
            text = text.strip()
            out.append((n, label, None, []))
            label = None
        if not text:
            continue
        parts = text.replace(',', ' ').split()
        out.append((n, None, parts[0].lower(), parts[1:]))
    return out


def expand_pseudo(mnem, ops):
    """Rewrite pseudo-instructions into their base form."""
    if mnem == 'nop':
        return 'addi', ['x0', 'x0', '0']
    if mnem == 'li':
        return 'addi', [ops[0], 'x0', ops[1]]
    if mnem == 'mv':
        return 'addi', [ops[0], ops[1], '0']
    if mnem == 'j':
        return 'jal', ['x0', ops[0]]
    if mnem == 'jr':
        return 'jalr', ['x0', '0(%s)' % ops[0]]
    if mnem == 'ret':
        return 'jalr', ['x0', '0(ra)']
    if mnem == 'beqz':
        return 'beq', [ops[0], 'x0', ops[1]]
    if mnem == 'bnez':
        return 'bne', [ops[0], 'x0', ops[1]]
    return mnem, ops


def assemble(src):
    items = tokenize(src)

    # pass 1: label addresses
    labels, pc = {}, 0
    for n, label, mnem, ops in items:
        if label is not None:
            if label in labels:
                raise AsmError("line %d: duplicate label %r" % (n, label))
            labels[label] = pc
        elif mnem is not None:
            pc += 4

    # pass 2: encode
    words, pc = [], 0
    for n, label, mnem, ops in items:
        if mnem is None:
            continue
        mnem, ops = expand_pseudo(mnem, ops)
        w = encode(mnem, ops, labels, pc, n)
        words.append((pc, w, mnem, ops))
        pc += 4
    return words


def encode(mnem, ops, labels, pc, n):
    def need(k):
        if len(ops) != k:
            raise AsmError("line %d: %s expects %d operands, got %d"
                           % (n, mnem, k, len(ops)))

    if mnem in R_TYPE:
        need(3)
        f7, f3 = R_TYPE[mnem]
        return enc_r(f7, reg(ops[2], n), reg(ops[1], n), f3, reg(ops[0], n), OP_R)

    if mnem in I_TYPE:
        need(3)
        v = imm(ops[2], labels, pc, n)
        fits(v, 12, n, "immediate")
        return enc_i(v, reg(ops[1], n), I_TYPE[mnem], reg(ops[0], n), OP_I)

    if mnem in SH_TYPE:
        need(3)
        f7, f3 = SH_TYPE[mnem]
        sh = imm(ops[2], labels, pc, n)
        if not 0 <= sh <= 31:
            raise AsmError("line %d: shift amount %d out of range [0,31]" % (n, sh))
        return enc_i((f7 << 5) | sh, reg(ops[1], n), f3, reg(ops[0], n), OP_I)

    if mnem in LOADS:
        need(2)
        off, base = memref(ops[1], n)
        fits(off, 12, n, "load offset")
        return enc_i(off, base, LOADS[mnem], reg(ops[0], n), OP_LD)

    if mnem in STORES:
        need(2)
        off, base = memref(ops[1], n)
        fits(off, 12, n, "store offset")
        return enc_s(off, reg(ops[0], n), base, STORES[mnem], OP_ST)

    if mnem in BRANCHES:
        need(3)
        off = imm(ops[2], labels, pc, n, rel=True)
        fits(off, 13, n, "branch offset")
        if off & 1:
            raise AsmError("line %d: odd branch offset %d" % (n, off))
        return enc_b(off, reg(ops[1], n), reg(ops[0], n), BRANCHES[mnem], OP_BR)

    if mnem in ('lui', 'auipc'):
        need(2)
        v = imm(ops[1], labels, pc, n)
        if not 0 <= v <= 0xFFFFF:
            raise AsmError("line %d: %s immediate %d out of range [0,0xFFFFF]"
                           % (n, mnem, v))
        return enc_u(v, reg(ops[0], n), OP_LUI if mnem == 'lui' else OP_AUIPC)

    if mnem == 'jal':
        need(2)
        off = imm(ops[1], labels, pc, n, rel=True)
        fits(off, 21, n, "jump offset")
        return enc_j(off, reg(ops[0], n), OP_JAL)

    if mnem == 'jalr':
        need(2)
        off, base = memref(ops[1], n)
        fits(off, 12, n, "jalr offset")
        return enc_i(off, base, 0x0, reg(ops[0], n), OP_JALR)

    if mnem == 'ecall':
        return enc_i(0, 0, 0, 0, OP_SYS)
    if mnem == 'ebreak':
        return enc_i(1, 0, 0, 0, OP_SYS)
    if mnem == 'fence':
        return enc_i(0, 0, 0, 0, OP_FENCE)
    if mnem == 'fence.i':
        return enc_i(0, 0, 1, 0, OP_FENCE)

    raise AsmError("line %d: unknown instruction %r" % (n, mnem))


def main():
    ap = argparse.ArgumentParser(description="RV32I assembler for ThetaCore")
    ap.add_argument("source")
    ap.add_argument("-o", "--output", required=True)
    ap.add_argument("--plain", action="store_true",
                    help="emit bare hex with no source annotations")
    ap.add_argument("--pad", type=int, default=128,
                    help="pad the image to this many words (default 128, the "
                         "SRAM depth; avoids a $readmemh short-file warning)")
    args = ap.parse_args()

    with open(args.source) as f:
        src = f.read()

    try:
        words = assemble(src)
    except AsmError as e:
        print("error: %s" % e, file=sys.stderr)
        return 1

    lines = []
    for pc, w, mnem, ops in words:
        if args.plain:
            lines.append("%08x" % w)
        else:
            lines.append("%08x  // %04x: %s %s" % (w, pc, mnem, ' '.join(ops)))

    n_instr = len(lines)
    while len(lines) < args.pad:
        lines.append("00000000")

    with open(args.output, 'w') as f:
        f.write('\n'.join(lines) + '\n')

    print("assembled %d instructions (padded to %d words) -> %s"
          % (n_instr, len(lines), args.output))
    return 0


if __name__ == "__main__":
    sys.exit(main())
