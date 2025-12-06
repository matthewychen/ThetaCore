module CU_EX(
    // Clock and control inputs
    input soc_clk,
    input EX_reset,
    
    // Data inputs
    input [31:0] rs1_data,
    input [31:0] rs2_data,
    input [31:0] imm_data,
    input [4:0] Instruction_to_ALU,

    // Outputs
    output [31:0] result_data,
    output result_ready,
    output overflow_flag,
    output zero_flag,
    output condition_met_flag,
    output error_flag
);

    // Internal signals

    reg dat_ready;
    reg [31:0] ALU_dat1;
    reg [31:0] ALU_dat2;
    
    // 4-stage execution counter
    reg [1:0] EX_stage_counter;
    
    // Registered input values
    reg [31:0] reg_rs1_data;
    reg [31:0] reg_rs2_data;
    reg [31:0] reg_imm_data;
    reg [4:0] reg_instruction_to_ALU;

    always@(posedge soc_clk or posedge EX_reset) begin
        if(EX_reset) begin
            // Immediate reset response
            EX_stage_counter <= 00;
            reg_rs1_data <= 0;
            reg_rs2_data <= 0;
            reg_imm_data <= 0;
            reg_instruction_to_ALU <= 0;
        end else begin
            EX_stage_counter <= EX_stage_counter + 1;
            case(EX_stage_counter)
                2'b00: begin // Stage 0: Save incoming values / latch data
                    reg_rs1_data <= rs1_data;
                    reg_rs2_data <= rs2_data;
                    reg_imm_data <= imm_data;
                    reg_instruction_to_ALU <= Instruction_to_ALU;
                end
                
                2'b01: begin // drive ALU
                        dat_ready <= 1'b1;  // Start ALU
                end
                
                2'b10: begin // Stage 2: Processing time
                end
                
                2'b11: begin // Stage 3: Finished
                    // Output capture is in separate always block
                    dat_ready <= 1'b0;  // ALU is working
                end
            endcase
        end
    end

    // Instantiate ALU_top
    ALU_top ALU(
        .soc_clk(soc_clk),
        .reset(EX_reset),
        .dat_ready(dat_ready),
        .ALU_dat1(ALU_dat1),
        .ALU_dat2(ALU_dat2),
        .Instruction_to_ALU(reg_instruction_to_ALU),
        .ALU_overflow(overflow_flag),
        .ALU_con_met(condition_met_flag),
        .ALU_zero(zero_flag),
        .ALU_err(error_flag),
        .ALU_ready(result_ready),
        .ALU_out(result_data)
    );

endmodule