module CU_EX(
    input soc_clk,
    input EX_reset,
    input [31:0] rs1_data,
    input [31:0] rs2_data,
    input [31:0] imm_data,
    input [5:0] Instruction_to_ALU, //instruction out of CU
    output [31:0] result_data,
    output result_ready,
    output overflow_flag,
    output zero_flag,
    output condition_met_flag,
    output error_flag,
    output EX_accept,
    output [1:0] stage_counter
);

    reg dat_ready;
    
    always@(posedge soc_clk or posedge EX_reset) begin
        if(EX_reset) begin
        end
        else begin
        end
    end

    ALU_top ALU(
        .soc_clk(soc_clk),
        .reset(EX_reset),
        .ALU_dat1(rs1_data),
        .ALU_dat2(rs2_data),
        .Instruction_from_CU(Instruction_to_ALU),
        .ALU_overflow(overflow_flag),
        .ALU_con_met(condition_met_flag),
        .ALU_zero(zero_flag),
        .ALU_err(error_flag),
        .ALU_ready(result_ready),
        .ALU_out(result_data),
        .ALU_accept(EX_accept),
        .ALU_result_counter(stage_counter)
    );

endmodule