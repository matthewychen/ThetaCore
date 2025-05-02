module CU_EX(
    // Clock and control inputs
    input wire soc_clk,
    input wire EX_reset,
    input wire EX_stall,
    
    // Data inputs
    input wire [31:0] rs1_data,
    input wire [31:0] rs2_data,
    input wire [31:0] imm_data,
    input wire [4:0] Instruction_to_ALU,
    input wire pipelining_override,

    // Outputs
    output reg [31:0] result_data,
    output reg result_ready,
    output reg overflow_flag,
    output reg zero_flag,
    output reg condition_met_flag,
    output reg error_flag
);

    // Internal signals
    reg dat_ready;
    reg [31:0] ALU_dat1;
    reg [31:0] ALU_dat2;
    
    // 4-stage execution counter
    reg [1:0] stage_counter;
    
    // Registered input values
    reg [31:0] reg_rs1_data;
    reg [31:0] reg_rs2_data;
    reg [31:0] reg_imm_data;
    reg [4:0] reg_instruction_to_ALU;
    
    // ALU output signals
    wire ALU_overflow;
    wire ALU_con_met;
    wire ALU_zero;
    wire ALU_err;
    wire ALU_ready;
    wire [31:0] ALU_out;
    
    // Counter initialization and control
    always @(posedge soc_clk or posedge EX_reset) begin
        if (EX_reset) begin
            stage_counter <= 2'b00;  // Reset to stage 0
        end else if (!EX_stall) begin
            // Only increment if not stalled
            stage_counter <= stage_counter + 1'b1;
        end
    end
    
    // Data capture and ALU control state machine
    always @(posedge soc_clk or posedge EX_reset) begin
        if (EX_reset) begin
            // Reset state
            dat_ready <= 1'b0;
            reg_rs1_data <= 32'b0;
            reg_rs2_data <= 32'b0;
            reg_imm_data <= 32'b0;
            reg_instruction_to_ALU <= 5'b0;
            ALU_dat1 <= 32'b0;
            ALU_dat2 <= 32'b0;
        end else begin
            case(stage_counter)
                2'b00: begin // Stage 0: Save incoming values
                    if (!EX_stall) begin
                        reg_rs1_data <= rs1_data;
                        reg_rs2_data <= rs2_data;
                        reg_imm_data <= imm_data;
                        reg_instruction_to_ALU <= Instruction_to_ALU;
                    end
                    dat_ready <= 1'b0;
                end
                
                2'b01: begin // Stage 1: Maybe override inputs
                    if (!EX_stall) begin
                        if (pipelining_override) begin
                            // Recollect rs1/rs2 if pipeline override
                            ALU_dat1 <= rs1_data;
                            ALU_dat2 <= rs2_data;
                        end else begin
                            // Use registered values
                            ALU_dat1 <= reg_rs1_data;
                            ALU_dat2 <= reg_imm_data;
                        end
                        dat_ready <= 1'b1;  // Start ALU
                    end
                end
                
                2'b10: begin // Stage 2: Processing
                end
                
                2'b11: begin // Stage 3: Finished
                    // Output capture is in separate always block
                    dat_ready <= 1'b0;  // ALU is working
                end
            endcase
        end
    end
    
    // Transfer ALU outputs at Stage 3 unless stalled
    always @(posedge soc_clk or posedge EX_reset) begin
        if (EX_reset) begin
            result_data <= 32'b0;
            result_ready <= 1'b0;
            overflow_flag <= 1'b0;
            zero_flag <= 1'b0;
            condition_met_flag <= 1'b0;
            error_flag <= 1'b0;
        end else if (stage_counter == 2'b11 && !EX_stall && ALU_ready) begin
            result_data <= ALU_out;
            result_ready <= 1'b1;
            overflow_flag <= ALU_overflow;
            zero_flag <= ALU_zero;
            condition_met_flag <= ALU_con_met;
            error_flag <= ALU_err;
        end else if (stage_counter == 2'b00) begin
            // Reset ready flag at beginning of new cycle
            result_ready <= 1'b0;
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
        .ALU_overflow(ALU_overflow),
        .ALU_con_met(ALU_con_met),
        .ALU_zero(ALU_zero),
        .ALU_err(ALU_err),
        .ALU_ready(ALU_ready),
        .ALU_out(ALU_out)
    );

endmodule