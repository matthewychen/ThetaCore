# ##THETACORE™️ RISC-V CPU##

This is a project that aims to construct a RISC-V ISA-based CPU (and associated RAM), using the R32I instruction set (and the R32F extension if time and interest permit).

#### To build:

install icarusverilog sim and gtkwave from respective vendors. Then run:

iverilog -g2012 -f list.f -o testsim
vvp testsim

To view waveform:
gtkwave.exe wave.vcd (or your dumpfile name)