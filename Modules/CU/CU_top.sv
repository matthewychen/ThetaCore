module ControlUnit(
    //templated
    input soc_clk,
    input reset,

    //need 
    //ports to ALU in1 in2 set, 
    //module to handle flag from branch command,
    //32x general purpose registers, special registers PC (needs to be able to handle jal/jalr), IR, MDR, MAR, TEMP. dont use sram, just use builtin... sram is too much of a headache and would add additional lag
    //decode functionality to handle add/addi register placement
    //pipelining override #################### important dont forget. use signal from IDU_top
    //branch command handler:
    //on negedge

    //$finish on posedge ALU_err or CU unable to decode

    //for JALR and JAL, make sure to stall and wait for those instructions to finish before proceeding

    input [31:0] CU_in,
    output [31:0] CU_out
);

always@(posedge ALU_err or posedge CU_decode_error) begin
    $finish;
end

CU_decrpyt CU_decrypt_inst(
    .CU_out(CU_out)
);

endmodule