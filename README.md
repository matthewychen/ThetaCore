# ThetaCore™ RISC-V CPU 🤖

This is a project that aims to construct a single RISC-V ISA-based CPU and associated RAM using the R32I instruction set (and the R32F extension if time and interest permit).

Key features will include conditional branching, pipelining, ALUops, and 4kb of user-dictable memory.

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