module CU_ID(
    // Clock and control inputs
    input soc_clk,
    input ID_reset,
    input ID_stall,
    input ID_poweron,

    input decode_start,    // From CU to trigger decode
    input IDU_reset,       // Reset signal for flush
    input [31:0] Cu_IR,    // Instruction from CU

    // Outputs to CU_top
    output reg IDU_ready,                // Decode completion signal
    output reg [5:0] Instruction_to_CU,  // Decoded instruction type
    output reg [4:0] Instruction_to_ALU, // ALU operation code
    output reg [31:0] imm,              // Immediate value
    output reg [4:0] rd,                // Destination register
    output reg [4:0] rs1,               // Source register 1
    output reg [4:0] rs2,               // Source register 2
    output reg [4:0] shamt,             // Shift amount
    output reg [31:0] pc_increment,     // PC increment value
    output reg [1:0] pipeline_override, // Pipeline hazard control
    output reg invalid_instruction      // Error flag
);

reg ID_ready_reg;
reg [5:0] Instruction_to_CU_reg;  // Decoded instruction type
reg [4:0] Instruction_to_ALU_reg; // ALU operation code
reg [31:0] imm_reg;              // Immediate value
reg [4:0] rd_reg;                // Destination register
reg [4:0] rs1_reg;               // Source register 1
reg [4:0] rs2_reg;               // Source register 2
reg [4:0] shamt_reg;             // Shift amount
reg [31:0] pc_increment_reg;     // PC increment value
reg [1:0] pipeline_override_reg; // Pipeline hazard control
reg invalid_instruction_reg;      // Error flag

//save instruction in register every time new data is available, unless stalled
reg [31:0] reg_instruction;
reg [1:0] ID_stage_counter;

//reset and stall capture
reg ID_reset_reg;
reg ID_stall_reg;

always@(posedge soc_clk or posedge ID_reset) begin
    if(ID_reset) begin
        // Immediate reset response
        ID_reset_reg <= 1;
    end else if(ID_stall) begin
        // Set stall flag
        ID_stall_reg <= 1;
    end else if(ID_stage_counter == 2'b00) begin
        // Clear flags only at stage 0 and if no new reset/stall
        ID_reset_reg <= 0;
        ID_stall_reg <= 0;
    end
end

always@(posedge Fetch_ready) begin
    if(!IDU_stall) begin
        reg_instruction <= Cu_IR;
    end
end

//Unconditional stage counter incrementation

always@(posedge ID_poweron) begin //happens once on poweron
    ID_stage_counter <= 2'b11; //let it wrap to 00 on the first posedge of soc_clk
    ID_reset_reg <= 0;
    ID_stall_reg <= 0;
end

always @(posedge soc_clk) begin //unconditional stage incrementation
    ID_stage_counter <= ID_stage_counter + 1'b1;
end

always @(posedge soc_clk or posedge ID_reset_reg) begin
    if (ID_reset_reg) begin
        // Reset state
    end else begin
        case(ID_stage_counter)
            2'b00: begin // Stage 0: Save incoming values
            end
            
            2'b01: begin // Stage 1: Maybe override inputs
            end
            
            2'b10: begin // Stage 2: Processing time
            end
            
            2'b11: begin // Stage 3: Finished
            //IDU_ready should be asserted here. Drive all data
            if(IDU_ready_reg) begin
                ID_ready <= 1;
                Instruction_to_CU = Instruction_to_CU_reg;
                Instruction_to_ALU = Instruction_to_ALU_reg; 
                imm = imm_reg;
                rd =rd_reg;
                rs1 = rs1_reg;
                rs2 = rs2_reg;
                shamt = shamt_reg;
                pc_increment = pc_increment_reg;
                pipeline_override = pipeline_override_reg;
                invalid_instruction = invalid_instruction_reg;
            end
            end
        endcase
    end
end


// Instantiate and connect to the Instruction Decode Unit
IDU_top instruction_decode_unit(
    .soc_clk(soc_clk),
    .IDU_reset(reset),
    .Fetch_ready(decode_start),    // Connect to decode_start from CU
    .instruction(reg_instruction),           // Connect to instruction from CU
    .IDU_stall(IDU_stall),         // Connect to stall signal
    .IDU_poweron(ID_poweron),
    
    // Connect all outputs (using direct pass-through)
    .IDU_ready(IDU_ready_reg),
    .Instruction_to_CU(Instruction_to_CU_reg),
    .Instruction_to_ALU(Instruction_to_ALU_reg),
    .imm(imm_reg),
    .rd(rd_reg),
    .rs1(rs1_reg),
    .rs2(rs2_reg),
    .shamt(shamt_reg),
    .pc_increment(pc_increment_reg),
    .pipeline_override(pipeline_override_reg),
    .invalid_instruction(invalid_instruction_reg)
);

endmodule
