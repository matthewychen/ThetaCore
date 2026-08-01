# ThetaCore™ RISC-V CPU 🤖

This is a project that aims to construct a single RISC-V ISA-based CPU and associated RAM using the R32I instruction set (and the R32F extension if time and interest permit).

Key features will include conditional branching, ALUops, and 4kb of user-dictable memory.

#### To create testbench:

install icarusverilog sim and gtkwave from respective vendors (don't use icarusverilog bundled gtkwave, I noticed performance issues); add both to PATH. cd into /Testbench. Modify list.f as needed to define compilation list. Then run:

```
iverilog -g2012 -f list.f -o testsim
vvp testsim
```

To view waveform:
```
gtkwave.exe wave.vcd (or your dumpfile name, can be changed in tb_top)
```

#### To trace execution:

add +TRACE to print one line per instruction — the PC, the instruction word, and which register changed:

```
vvp testsim +TRACE
```

```
TRACE pc=00000008 inst=002081b3  x3: 00000000 -> 0000000c
TRACE pc=00000010 inst=04302023  (no register write)
```

#### To assemble a program:

write RV32I assembly (see /programs for examples), then run tools/asm.py to produce a hex image. needs python 3, no RISC-V toolchain:

```
python tools/asm.py programs/arith.s -o programs/arith.hex
```

registers by number (x5) or ABI name (t0); labels end in ':'; comments with # or //; loads and stores use offset(base). branch and jump targets are labels. pseudo-instructions: nop, li, mv, j, jr, ret, beqz, bnez.

the image is loaded into SRAM with the +PROG plusarg. swap list.f to tb_run rather than tb_cpu, which loads its own programs and ignores +PROG:

```
vvp testsim +PROG=../programs/arith.hex
```

programs load at address 0 and memory is unified, so keep data clear of the program — the examples use addresses from 64 upward.

Ecall/Ebreak are treated as program terminations. FENCE is treated as FENCE.I for simplicity!

### Todo:
- ~~assembler that will translate assembly code into .bin?~~ done, tools/asm.py