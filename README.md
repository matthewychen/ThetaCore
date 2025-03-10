# ThetaCore™ RISC-V CPU

This is a project that aims to construct a single RISC-V ISA-based CPU and associated RAM using the R32I instruction set (and the R32F extension if time and interest permit).

Key features will include conditional branching, ALUops, and 2kb of user-dictable memory. I also aim to make a rudimentary compiler that will translate assembly code into executable binary.

#### To create testbench:

install icarusverilog sim and gtkwave from respective vendors (don't use icarusverilog bundled gtkwave, I noticed performance issues). cd into /Testbench. Then run:

```
iverilog -g2012 -f list.f -o testsim
vvp testsim
```

To view waveform:
```
gtkwave.exe wave.vcd (or your dumpfile name, can be changed in tb_top)
```

RISCV binary can be compiled and directly saved to bits.bin. The data will be loaded into SRAM with the tb block.