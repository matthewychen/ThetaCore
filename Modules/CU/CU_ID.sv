module CU_ID(
    // Clock and control inputs
    input wire soc_clk,
    input wire ID_reset,
    input wire [31:0] Cu_IR,    // Instruction from CU
    input wire [1:0] stage_counter, //generate stage counter in CU_top

    // Outputs to CU_top
    output wire [5:0] Instruction_to_CU,
    output wire [31:0] imm,
    output wire [4:0] rd,
    output wire [4:0] rs1,
    output wire [4:0] rs2,
    output wire [4:0] shamt,
    output wire [31:0] pc_increment,
    output wire invalid_instruction
);

    // Instantiate IDU_top
    IDU_top IDU (
        .soc_clk(soc_clk),
        .IDU_reset(ID_reset),
        .instruction(Cu_IR),
        .Instruction_to_CU(Instruction_to_CU),
        .imm(imm),
        .rd(rd),
        .rs1(rs1),
        .rs2(rs2),
        .shamt(shamt)
    );

endmodule