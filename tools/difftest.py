#!/usr/bin/env python3
"""
Randomised differential test: RTL versus the reference model.

    python tools/difftest.py --runs 200

Generates random RV32I programs, executes each on both the Verilog core and
tools/rvmodel.py, and compares all 32 registers plus all 128 memory words.

Termination is structural: every control transfer generated is FORWARD and
bounded by the ecall in the final slot, so no generated program can loop.

Failing programs are written to failures/ with the diff, so a mismatch is
immediately reproducible.
"""

import argparse
import os
import random
import re
import subprocess
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(HERE)
sys.path.insert(0, HERE)

from asm import enc_r, enc_i, enc_s, enc_b, enc_u, enc_j  # noqa: E402
from rvmodel import Model                                  # noqa: E402

OP_R, OP_I, OP_LD, OP_ST = 0x33, 0x13, 0x03, 0x23
OP_BR, OP_LUI, OP_AUIPC, OP_JAL, OP_JALR, OP_SYS = 0x63, 0x37, 0x17, 0x6F, 0x67, 0x73

R_OPS = [(0x00, 0x0), (0x20, 0x0), (0x00, 0x1), (0x00, 0x2), (0x00, 0x3),
         (0x00, 0x4), (0x00, 0x5), (0x20, 0x5), (0x00, 0x6), (0x00, 0x7)]
I_OPS = [0x0, 0x2, 0x3, 0x4, 0x6, 0x7]
SH_OPS = [(0x00, 0x1), (0x00, 0x5), (0x20, 0x5)]
LD_OPS = [0x0, 0x1, 0x2, 0x4, 0x5]
ST_OPS = [0x0, 0x1, 0x2]
BR_OPS = [0x0, 0x1, 0x4, 0x5, 0x6, 0x7]

PROG_WORDS = 28      # instruction slots
DATA_LO = 32         # first data word; keeps stores clear of the program
DATA_HI = 127
MEM_WORDS = 128


def data_addr(rng, align):
    """A byte address inside the data region, aligned as requested."""
    w = rng.randint(DATA_LO, DATA_HI)
    off = rng.choice({1: [0, 1, 2, 3], 2: [0, 2], 4: [0]}[align])
    return w * 4 + off


def gen_program(rng):
    n = PROG_WORDS
    last = n - 1
    prog = []
    for i in range(last):
        kind = rng.choice(['r', 'r', 'i', 'i', 'sh', 'lui', 'auipc',
                           'load', 'store', 'br', 'br', 'jal', 'jalr'])
        rd = rng.randrange(32)
        rs1 = rng.randrange(32)
        rs2 = rng.randrange(32)

        if kind == 'r':
            f7, f3 = rng.choice(R_OPS)
            prog.append(enc_r(f7, rs2, rs1, f3, rd, OP_R))
        elif kind == 'i':
            f3 = rng.choice(I_OPS)
            prog.append(enc_i(rng.randint(-2048, 2047), rs1, f3, rd, OP_I))
        elif kind == 'sh':
            f7, f3 = rng.choice(SH_OPS)
            prog.append(enc_i((f7 << 5) | rng.randrange(32), rs1, f3, rd, OP_I))
        elif kind == 'lui':
            prog.append(enc_u(rng.randrange(1 << 20), rd, OP_LUI))
        elif kind == 'auipc':
            prog.append(enc_u(rng.randrange(1 << 20), rd, OP_AUIPC))
        elif kind == 'load':
            f3 = rng.choice(LD_OPS)
            align = {0: 1, 4: 1, 1: 2, 5: 2, 2: 4}[f3]
            # base x0 so the effective address is exactly the immediate
            prog.append(enc_i(data_addr(rng, align), 0, f3, rd, OP_LD))
        elif kind == 'store':
            f3 = rng.choice(ST_OPS)
            align = {0: 1, 1: 2, 2: 4}[f3]
            prog.append(enc_s(data_addr(rng, align), rs2, 0, f3, OP_ST))
        elif kind == 'br':
            f3 = rng.choice(BR_OPS)
            tgt = rng.randint(i + 1, last)          # forward only
            prog.append(enc_b((tgt - i) * 4, rs2, rs1, f3, OP_BR))
        elif kind == 'jal':
            tgt = rng.randint(i + 1, last)          # forward only
            prog.append(enc_j((tgt - i) * 4, rd, OP_JAL))
        else:  # jalr, rs1 = x0 so the target is the immediate and stays bounded
            tgt = rng.randint(i + 1, last)
            prog.append(enc_i(tgt * 4, 0, 0x0, rd, OP_JALR))

    prog.append(enc_i(0, 0, 0, 0, OP_SYS))          # ecall, always reachable

    image = prog + [0] * (DATA_LO - len(prog))
    image += [rng.randrange(1 << 32) for _ in range(DATA_LO, MEM_WORDS)]
    return image


STATE = re.compile(r'^([xm]\d+)=([0-9a-fA-F]{8})$')
PCLINE = re.compile(r'^HALT pc=(\d+)')


def parse(lines):
    st, pc, halted = {}, None, False
    for ln in lines:
        ln = ln.strip()
        m = STATE.match(ln)
        if m:
            st[m.group(1)] = m.group(2).lower()
            continue
        m = PCLINE.match(ln)
        if m:
            pc, halted = int(m.group(1)), True
    return st, pc, halted


def run_rtl(vvp, image_path):
    out = subprocess.run(["vvp", vvp, "+PROG=" + image_path],
                         capture_output=True, text=True, timeout=120)
    return out.stdout.splitlines()


def run_model(image):
    m = Model(MEM_WORDS)
    m.mem = list(image)
    m.run()
    return m.dump(), m


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--runs", type=int, default=100)
    ap.add_argument("--seed", type=int, default=1)
    ap.add_argument("--vvp", default="/tmp/run.vvp",
                    help="compiled tb_run simulation")
    args = ap.parse_args()

    rng = random.Random(args.seed)
    faildir = os.path.join(ROOT, "failures")
    tmp = os.path.join(ROOT, "programs", "_difftest.hex")

    ok = fail = 0
    for run in range(args.runs):
        image = gen_program(rng)
        with open(tmp, "w") as f:
            f.write('\n'.join("%08x" % w for w in image) + '\n')

        rtl_st, rtl_pc, rtl_halt = parse(run_rtl(args.vvp, tmp))
        mdl_lines, mdl = run_model(image)
        mdl_st, mdl_pc, mdl_halt = parse(mdl_lines)

        diffs = []
        if rtl_halt != mdl_halt:
            diffs.append("halted: rtl=%s model=%s" % (rtl_halt, mdl_halt))
        if rtl_halt and mdl_halt and rtl_pc != mdl_pc:
            diffs.append("pc: rtl=%d model=%d" % (rtl_pc, mdl_pc))
        for k in sorted(set(rtl_st) | set(mdl_st),
                        key=lambda s: (s[0], int(s[1:]))):
            if rtl_st.get(k) != mdl_st.get(k):
                diffs.append("%s: rtl=%s model=%s"
                             % (k, rtl_st.get(k), mdl_st.get(k)))

        if diffs:
            fail += 1
            os.makedirs(faildir, exist_ok=True)
            base = os.path.join(faildir, "seed%d_run%d" % (args.seed, run))
            with open(base + ".hex", "w") as f:
                f.write('\n'.join("%08x" % w for w in image) + '\n')
            with open(base + ".diff", "w") as f:
                f.write('\n'.join(diffs) + '\n')
            print("run %d: MISMATCH (%d fields) -> %s.hex"
                  % (run, len(diffs), base))
            for d in diffs[:8]:
                print("    " + d)
        else:
            ok += 1

    if os.path.exists(tmp):
        os.remove(tmp)

    print("")
    print("difftest: %d passed, %d failed (seed=%d)" % (ok, fail, args.seed))
    return 1 if fail else 0


if __name__ == "__main__":
    sys.exit(main())
