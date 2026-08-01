# ThetaCore™ RISC-V CPU 🤖

This is a project that aims to construct a single RISC-V ISA-based CPU and associated RAM using the R32I instruction set (and the R32F extension if time and interest permit).

Key features include conditional branching, jump-and-link, ALU operations, and byte / halfword / word memory access with correct sign extension.

The core is a **multi-cycle** design: five states (IF, ID, EX, MEM, WB), one instruction in flight. Multi-cycle rather than single-cycle because the SRAM is synchronous — it registers its read, so an address presented this cycle returns data the next. Single-cycle datapaths (including the Berkeley RV32I diagram this is modelled on) assume asynchronous memory, which no real SRAM provides.

Memory is currently 128 words (512 bytes). Reaching the 4kb target needs a wider address decode in the MMU and a larger array in `SRAM_sim`.

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

RISCV binary can be compiled and directly saved to bits.bin. The data will be loaded into SRAM with the tb block.

Ecall/Ebreak are treated as program terminations. FENCE is treated as FENCE.I for simplicity!

### Todo:
- assembler that will translate assembly code into .bin?