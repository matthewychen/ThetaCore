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
    //00 -> no override
    //01 -> override rs1
    //10 -> override rs2
    input invalid_instruction

    //need 
    //ports to ALU in1 in2 command,
    //module to handle flag from branch command,
    //32x general purpose registers, special registers PC (needs to be able to handle jal/jalr), IR, MDR, MAR, TEMP. dont use sram, just use builtin... sram is too much of a headache and would add additional lag
    //decode functionality to handle add/addi register placement
    //pipelining override #################### important dont forget. use signal from IDU_top
    //branch command handler:
    //on negedge

    //$finish on posedge any error, ecall, or ebreak.

    //for JALR and JAL, make sure to stall and wait for those instructions to finish before proceeding

);

always@(posedge ALU_err or posedge CU_decode_error) begin
    $finish;
end

CU_decrpyt CU_decrypt_inst(
    .CU_out(CU_out)
);

endmodule