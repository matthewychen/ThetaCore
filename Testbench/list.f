//LEAVE 1L WHITESPACE AT END FOR COMPILATION
//
// Default target is the full core, CPU_TB/tb_cpu.sv.
// To run a unit testbench instead, comment that line out and uncomment
// the one you want from the list at the bottom.

+incdir+.
+incdir+..

// ---- control and datapath ----
../Modules/CU/CU_top.sv
../Modules/CU/CU_ID.sv
../Modules/CU/CU_EX.sv
../Modules/IDU/IDU_top.sv
../Modules/regfile.sv
../Modules/pc_unit.sv
../Modules/MMU.sv
../SRAM/SRAM_sim.sv

// ---- ALU ----
../Modules/ALU/ALU_top.sv
../Modules/ALU/ALU_Addsub.sv
../Modules/ALU/ALU_Logop.sv
../Modules/ALU/ALU_Shifter.sv
../Modules/ALU/ALU_Comparator.sv

// ---- leaf components ----
../Components/Components/fulladder.sv
../Components/Components/rippleadder.sv
../Components/Components/twoscomp.sv

// ---- testbench: pick exactly one ----
// tb_cpu    self-contained, loads its own programs, the default regression
// tb_run    generic runner, loads whatever +PROG names (needs dut_top.sv above)
./CPU_TB/tb_cpu.sv
//./CPU_TB/tb_run.sv
//../Modules/dut_top.sv
//./IDU_TB/tb_idu.sv
//./ALU_TB/tb_alu.sv
//./SRAM_TB/tb_sram.sv
//./REGFILE_TB/tb_regfile.sv
//./PC_TB/tb_pc_unit.sv
//./MMU_TB/tb_mmu.sv
