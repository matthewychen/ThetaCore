# ThetaCore™ RISC-V CPU 🤖

A RISC-V RV32I CPU and its RAM, written from scratch in SystemVerilog. It runs
programs: arithmetic, memory access, branches and jumps all execute end to end
in simulation.

Implemented in full: all 40 RV32I instructions, conditional branching,
jump-and-link, and byte / halfword / word memory access with correct sign
extension at every alignment. (The R32F extension remains a maybe, if time and
interest permit.)

The core is a **multi-cycle** design: five states (IF, ID, EX, MEM, WB), one
instruction in flight. Multi-cycle rather than single-cycle because the SRAM is
synchronous — it registers its read, so an address presented this cycle returns
data the next.

Currently about 9–10 cycles per instruction, dominated by the memory path:
instruction fetch costs four cycles and a load or store costs four more, while
decode and execute are one cycle each.

Memory is currently 128 words (512 bytes). Reaching the 4kb target needs a wider
address decode in the MMU and a larger array in `SRAM_sim`.

Ecall/Ebreak are treated as program terminations. FENCE is treated as FENCE.I
for simplicity!

---

## To create testbench:

install icarusverilog sim and gtkwave from respective vendors (don't use
icarusverilog bundled gtkwave, I noticed performance issues); add both to PATH.
cd into /Testbench. Modify list.f as needed to define compilation list — it
defaults to the full core, and the unit testbenches are listed commented-out at
the bottom. Then run:

```
iverilog -g2012 -f list.f -o testsim
vvp testsim
```

To view waveform:
```
gtkwave cpu_wave.vcd CPU_TB/cpu.gtkw
```

`CPU_TB/cpu.gtkw` is a save file that pre-groups the FSM state, both operand mux
selects, the datapath busses and the low registers, so you aren't picking
signals out of the tree by hand. Load it from within GTKWave instead via
**File → Read Save File** if you prefer. FSM states are `0=IF 1=ID 2=EX 3=MEM
4=WB 5=HALT`.

Each testbench dumps a VCD named after itself: `cpu_wave.vcd`, `alu_wave.vcd`,
`mmu_wave.vcd`, and so on.

## Writing and running programs

`tools/asm.py` assembles RV32I source into a `$readmemh` image. Needs Python 3,
nothing else — no RISC-V toolchain required.

```
python tools/asm.py programs/arith.s -o programs/arith.hex
```

Load the image with the `+PROG` plusarg. `CPU_TB/tb_run.sv` is a generic runner
that executes any image to completion and dumps the final architectural state —
in `list.f`, comment out `./CPU_TB/tb_cpu.sv` and uncomment both
`./CPU_TB/tb_run.sv` and `../Modules/dut_top.sv`, then:

```
cd Testbench
iverilog -g2012 -f list.f -o testsim
vvp testsim +PROG=../programs/arith.hex
```

(`tb_cpu`, the default, loads its own programs internally and ignores `+PROG`.)

### Assembly syntax

Standard RV32I mnemonics. Registers by number (`x5`) or ABI name (`t0`).
Comments with `#` or `//`. Labels end in `:`. Immediates in decimal or `0x` hex.
Loads and stores use `offset(base)`.

```asm
# programs/arith.s
        addi    x1, x0, 5           # x1 = 5
        addi    x2, x0, 7           # x2 = 7
        add     x3, x1, x2          # x3 = 12
        sw      x3, 64(x0)          # store to address 64
        lw      x5, 64(x0)          # read it back
        ecall                       # halt
```

Branch and jump targets are labels; the assembler works out the relative offset:

```asm
        bne     x1, x2, skip        # not taken when x1 == x2
        addi    x3, x0, 1
skip:   jal     x5, done            # x5 gets the return address
        addi    x6, x0, 77          # skipped
done:   ecall
```

Pseudo-instructions: `nop`, `li rd, imm`, `mv rd, rs`, `j label`, `jr rs`,
`ret`, `beqz rs, label`, `bnez rs, label`.

### Assembler options

| Flag | Effect |
|---|---|
| `-o FILE` | output path (required) |
| `--plain` | bare hex, without the `// address: source` annotations |
| `--pad N` | pad the image to N words (default 128, the SRAM depth) |

Padding to the full SRAM depth avoids a `$readmemh` short-file warning.
Anything past the end of your program reads as zero.

**Memory layout.** The program loads at address 0 and executes from there, so
keep data clear of it — the sample programs use addresses from 64 upward. There
is one unified memory, so a store into the program region overwrites
instructions.

## Testbenches

| Testbench | Covers | Assertions |
|---|---|---|
| `IDU_TB` | instruction decode, all formats | 12 |
| `ALU_TB` | ALU ops, branches, address calculation | 24 |
| `SRAM_TB` | word and byte-enable writes | 6 |
| `REGFILE_TB` | register file, x0 hardwiring | 10 |
| `PC_TB` | PC update, branch and jump targets | 12 |
| `MMU_TB` | every width at every alignment, sign extension | 18 |
| `CPU_TB` | full core, two programs end to end | 15 |

## Verification

`tools/rvmodel.py` is an independent RV32I interpreter written from the ISA
specification rather than from the Verilog. `tools/difftest.py` generates random
programs, runs each on both the RTL and the model, and compares all 32 registers
and all 128 memory words.

```
python tools/difftest.py --runs 200 --seed 1 --vvp /path/to/runsim
```

Generated programs always terminate by construction: every control transfer is
forward and bounded by the `ecall` in the final slot. Mismatches are written to
`failures/` with the offending image and a diff, so they reproduce.

The model is a weaker oracle than
[spike](https://github.com/riscv-software-src/riscv-isa-sim), since the same
author wrote both it and the RTL — it catches transcription and encoding errors
reliably, but not a shared misreading of the spec. Swapping in spike would be a
strict improvement.

## Layout

```
Modules/        CU_top (FSM), IDU, ALU, regfile, pc_unit, MMU, dut_top
SRAM/           SRAM_sim
Components/     fulladder, rippleadder, twoscomp
Testbench/      one directory per testbench, plus list.f
tools/          asm.py, rvmodel.py, difftest.py
programs/       assembly sources and assembled images
cu_opcodes.vh   the instruction encoding and control signal contract
```

`cu_opcodes.vh` is the single source of truth for the opcode encoding and the
datapath control signals. Both the IDU and the ALU reference it, so the two
cannot silently drift apart.

## Todo:
- ~~assembler that will translate assembly code into .bin?~~ — `tools/asm.py`
- shrink the MMU access sequencer; it is the current bottleneck
- grow memory to the 4kb target
- swap the reference model for spike
- pipeline it (the ID/EX and EX/MEM boundary registers already exist)
