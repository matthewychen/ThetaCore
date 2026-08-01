#!/usr/bin/env python3
"""
Assemble, build, run, report.

    python compandrun.py programs/control.s

Does the whole loop in one step: assembles the source, rebuilds the design,
loads the image into SRAM, runs it to completion, prints an execution trace and
the final architectural state, and tells you where the waveform landed.

Drives CPU_TB/tb_run.sv directly rather than going through Testbench/list.f, so
nothing has to be edited between runs.

Options:
    --no-trace    skip the per-instruction trace
    --no-wave     skip the waveform dump (a little faster)
    --full        show all 32 registers and all 128 memory words, not just
                  the ones that are non-zero
    --gtkwave     open the waveform when the run finishes
    --max N       cycle limit before declaring a timeout (default 20000)
"""

import argparse
import os
import re
import shutil
import subprocess
import sys

ROOT = os.path.dirname(os.path.abspath(__file__))
BUILD = os.path.join(ROOT, "build")

# Explicit rather than globbed: a missing file should be a loud error, not a
# silently smaller design.
SOURCES = [
    "Testbench/CPU_TB/tb_run.sv",
    "Modules/dut_top.sv",
    "Modules/CU/CU_top.sv",
    "Modules/CU/CU_ID.sv",
    "Modules/CU/CU_EX.sv",
    "Modules/IDU/IDU_top.sv",
    "Modules/ALU/ALU_top.sv",
    "Modules/ALU/ALU_Addsub.sv",
    "Modules/ALU/ALU_Logop.sv",
    "Modules/ALU/ALU_Shifter.sv",
    "Modules/ALU/ALU_Comparator.sv",
    "Modules/regfile.sv",
    "Modules/pc_unit.sv",
    "Modules/MMU.sv",
    "SRAM/SRAM_sim.sv",
    "Components/Components/fulladder.sv",
    "Components/Components/rippleadder.sv",
    "Components/Components/twoscomp.sv",
]

SRAM_WORDS = 128


def die(msg):
    print("error: %s" % msg, file=sys.stderr)
    sys.exit(1)


def need(tool):
    if shutil.which(tool) is None:
        die("%s not found on PATH" % tool)


def run(cmd, cwd=None):
    return subprocess.run(cmd, cwd=cwd, capture_output=True, text=True)


def main():
    ap = argparse.ArgumentParser(add_help=True, description=__doc__,
                                 formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("source", help="assembly source (.s), or a prebuilt .hex")
    ap.add_argument("--no-trace", action="store_true")
    ap.add_argument("--no-wave", action="store_true")
    ap.add_argument("--full", action="store_true")
    ap.add_argument("--gtkwave", action="store_true")
    ap.add_argument("--max", type=int, default=20000)
    args = ap.parse_args()

    need("iverilog")
    need("vvp")

    src = os.path.abspath(args.source)
    if not os.path.exists(src):
        die("no such file: %s" % args.source)
    name = os.path.splitext(os.path.basename(src))[0]
    os.makedirs(BUILD, exist_ok=True)

    # ---- 1. assemble -------------------------------------------------------
    n_instr = None
    if src.lower().endswith(".hex"):
        hexfile = src
        print("[asm]   using prebuilt image %s" % os.path.relpath(src, ROOT))
    else:
        hexfile = os.path.join(BUILD, name + ".hex")
        r = run([sys.executable, os.path.join(ROOT, "tools", "asm.py"),
                 src, "-o", hexfile])
        if r.returncode:
            sys.stdout.write(r.stdout)
            sys.stderr.write(r.stderr)
            die("assembly failed")
        m = re.search(r"assembled (\d+) instructions", r.stdout)
        n_instr = int(m.group(1)) if m else None
        print("[asm]   %s" % r.stdout.strip().replace(ROOT + os.sep, ""))
        if n_instr and n_instr > SRAM_WORDS:
            die("program is %d instructions, SRAM holds %d words"
                % (n_instr, SRAM_WORDS))

    # ---- 2. build ----------------------------------------------------------
    sim = os.path.join(BUILD, "sim.vvp")
    missing = [s for s in SOURCES if not os.path.exists(os.path.join(ROOT, s))]
    if missing:
        die("missing source files: %s" % ", ".join(missing))

    cmd = ["iverilog", "-g2012",
           "-I", ROOT,
           "-I", os.path.join(ROOT, "Testbench"),
           "-o", sim] + [os.path.join(ROOT, s) for s in SOURCES]
    r = run(cmd, cwd=ROOT)
    if r.returncode or r.stderr.strip():
        sys.stderr.write(r.stderr)
        if r.returncode:
            die("compile failed")
    print("[build] ok")

    # ---- 3. run ------------------------------------------------------------
    plus = ["+PROG=" + hexfile, "+MAXCYC=%d" % args.max]
    if not args.no_trace:
        plus.append("+TRACE")
    if not args.no_wave:
        plus.append("+WAVE")
    r = run(["vvp", sim] + plus, cwd=BUILD)
    if r.returncode:
        sys.stderr.write(r.stderr)
        die("simulation failed")
    out = r.stdout.splitlines()

    # ---- 4. report ---------------------------------------------------------
    regs, mem, status = {}, {}, None
    trace = []
    for ln in out:
        if ln.startswith("TRACE"):
            trace.append(ln)
        elif ln.startswith("HALT") or ln.startswith("TIMEOUT"):
            status = ln
        else:
            m = re.match(r"^x(\d+)=([0-9a-f]{8})$", ln)
            if m:
                regs[int(m.group(1))] = m.group(2)
                continue
            m = re.match(r"^m(\d+)=([0-9a-f]{8})$", ln)
            if m:
                mem[int(m.group(1))] = m.group(2)

    if trace:
        print("")
        for ln in trace:
            print(ln)

    print("")
    if status is None:
        print("!! no halt status reported")
    elif status.startswith("TIMEOUT"):
        print("!! %s  (raise --max if the program is just slow)" % status)
    else:
        m = re.search(r"cycles=(\d+) retired=(\d+)", status)
        if m and int(m.group(2)):
            c, i = int(m.group(1)), int(m.group(2))
            print("%s  CPI=%.1f" % (status, c / float(i)))
        else:
            print(status)

    print("")
    print("registers:" if args.full else "registers (non-zero):")
    shown = 0
    for i in sorted(regs):
        if args.full or regs[i] != "00000000":
            print("  x%-2d = %s  (%d)" % (i, regs[i], int(regs[i], 16)))
            shown += 1
    if not shown:
        print("  (all zero)")

    skip = n_instr or 0
    print("")
    print("memory:" if args.full
          else "memory (non-zero, past the program):")
    shown = 0
    for i in sorted(mem):
        if args.full or (mem[i] != "00000000" and i >= skip):
            print("  [%3d] byte %3d = %s  (%d)"
                  % (i, i * 4, mem[i], int(mem[i], 16)))
            shown += 1
    if not shown:
        print("  (nothing written)")

    # ---- 5. waveform -------------------------------------------------------
    print("")
    if args.no_wave:
        print("waveform: skipped (--no-wave)")
    else:
        produced = os.path.join(BUILD, "run_wave.vcd")
        wave = os.path.join(BUILD, name + "_wave.vcd")
        if os.path.exists(produced):
            if os.path.exists(wave):
                os.remove(wave)
            os.rename(produced, wave)
            save = os.path.join(ROOT, "Testbench", "CPU_TB", "run.gtkw")
            print("waveform: %s" % wave)
            print("          gtkwave \"%s\" \"%s\"" % (wave, save))
            if args.gtkwave:
                if shutil.which("gtkwave"):
                    subprocess.Popen(["gtkwave", wave, save])
                else:
                    print("          (gtkwave not on PATH)")
        else:
            print("waveform: not produced")

    return 0


if __name__ == "__main__":
    sys.exit(main())
