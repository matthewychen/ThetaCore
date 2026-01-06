//LEAVE 1L WHITESPACE AT END FOR COMPILATION

+incdir+./Testbench

../SRAM/SRAMcell.sv
../SRAM/SRAMAddress.sv
../SRAM/SRAM.sv
../SRAM/SRAMbyte.sv
../SRAM/SRAM_sim.sv

//../Modules/ALU/ALU_Addsub.sv
//../Modules/CU/CU_EX.sv
//../Modules/ALU/ALU_LogOp.sv
//../Modules/ALU/ALU_Shifter.sv
//../Modules/ALU/ALU_Comparator.sv
//../Modules/ALU/ALU_top.sv


../Components/Components/fulladder.sv
../Components/Components/rippleadder.sv
../Components/Components/twoscomp.sv

../Modules/MMU.sv
./MMU_TB/tb_mmu.sv

//./tb_top.sv
//SRAM_TB/tb_sram.sv
//./IDU_TB/tb_idu.sv
//./ALU_TB/tb_alu.sv
//../Modules/IDU/IDU_top.sv
