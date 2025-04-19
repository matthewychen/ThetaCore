module ControlUnit(
    //templated
    input soc_clk,
    input reset,

    //from IDU
    input IDU_ready,
    input [5:0] Instruction_to_CU,
    input [4:0] Instruction_to_ALU, //needs to be outputted to ALU 1 clock cycle before dat_ready
    //databusses
    input [31:0] imm,
    input [4:0] rd, //CU register sel
    input [4:0] rs1,
    input [4:0] rs2,
    input [4:0] shamt,
    input [31:0] pc_increment,

    //flags
    input [1:0] pipeline_override,
    //00 -> no override on next instruction
    //01 -> override rs1
    //10 -> override rs2

    //need 
    //instantiation of ALU
    //module to handle flag from branch command,
    //32x general purpose registers, special registers PC (needs to be able to handle jal/jalr), IR, MDR, MAR, TEMP. dont use sram, just use builtin... sram is too much of a headache and would add additional lag
    //pipelining override #################### important dont forget. use signal from IDU_top
    //branch command handler:
    //on negedge

    //$finish on posedge any error, ecall, or ebreak.

    //for JALR and JAL, make sure to stall and wait for those instructions to finish before proceeding

);

reg [1:0] CU_result_counter; //actually needed in CU to implement pipelining override and coordinate various activities.

reg [31:0] CU_PC; //if PC > 4*128: kill
reg [31:0] CU_IR;
reg [31:0] CU_MDR;
reg [31:0] CU_MAR;
reg [31:0] CU_TEMP; //needed?

//31 general purpose registers and the zero register - x0 - x31                  | _ALIASES
reg [31:0] reg_00; //0 reg                                                       | zero
reg [31:0] reg_01; //return address                                              | ra
reg [31:0] reg_02; //stack pointer                                               | sp
reg [31:0] reg_03; //global pointer                                              | gp
reg [31:0] reg_04; //thread pointer. Will not implement (long explanation.)      | tp
reg [31:0] reg_05; //temp reg 0                                                  | t0
reg [31:0] reg_06; //temp reg 1                                                  | t1
reg [31:0] reg_07; //temp reg 2                                                  | t2
reg [31:0] reg_08; //saved reg 0 /frame pointer                                  | s0/fp
reg [31:0] reg_09; //saved reg 1                                                 | s1
reg [31:0] reg_10; //function arg 0                                              | a0
reg [31:0] reg_11; //function arg 1                                              | a1
reg [31:0] reg_12; //function arg 2                                              | a2
reg [31:0] reg_13; //function arg 3                                              | a3
reg [31:0] reg_14; //function arg 4                                              | a4
reg [31:0] reg_15; //function arg 5                                              | a5
reg [31:0] reg_16; //function arg 6                                              | a6
reg [31:0] reg_17; //function arg 7                                              | a7
reg [31:0] reg_18; //saved reg 2                                                 | s2
reg [31:0] reg_19; //saved reg 3                                                 | s3
reg [31:0] reg_20; //saved reg 4                                                 | s4
reg [31:0] reg_21; //saved reg 5                                                 | s5
reg [31:0] reg_22; //saved reg 6                                                 | s6
reg [31:0] reg_23; //saved reg 7                                                 | s7
reg [31:0] reg_24; //saved reg 8                                                 | s8
reg [31:0] reg_25; //saved reg 9                                                 | s9
reg [31:0] reg_26; //saved reg 10                                                | s10
reg [31:0] reg_27; //saved reg 11                                                | s11
reg [31:0] reg_28; //temp reg 3                                                  | t3
reg [31:0] reg_29; //temp reg 4                                                  | t4
reg [31:0] reg_30; //temp reg 5                                                  | t5
reg [31:0] reg_31; //temp reg 6                                                  | t6

always@(posedge ALU_err or posedge CU_decode_error) begin
    $finish;
end

CU_decrpyt CU_decrypt_inst(
    .CU_out(CU_out)
);

endmodule