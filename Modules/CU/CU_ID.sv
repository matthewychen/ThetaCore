module CU_ID(
    // Clock and control inputs
    input wire soc_clk,
    input wire ID_reset,
    input wire ID_stall,
    input wire decode_start,    // From CU to trigger decode
    input wire IDU_reset,       // Reset signal for flush
    input wire [31:0] Cu_IR,    // Instruction from CU

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

//save instruction in register every time new data is available, unless stalled
reg [31:0] reg_instruction;
reg [1:0] ID_stage_counter;

always@(posedge Fetch_ready) begin
    if(!IDU_stall) begin
        reg_instruction <= Cu_IR;
    end
end

initial begin
    ID_stage_counter <= 2'b11;
end


// Instantiate and connect to the Instruction Decode Unit
IDU_top instruction_decode_unit(
    .soc_clk(soc_clk),
    .IDU_reset(reset),
    .Fetch_ready(decode_start),    // Connect to decode_start from CU
    .instruction(reg_instruction),           // Connect to instruction from CU
    .IDU_stall(IDU_stall),         // Connect to stall signal
    
    // Connect all outputs (using direct pass-through)
    .IDU_ready(IDU_ready),
    .Instruction_to_CU(Instruction_to_CU),
    .Instruction_to_ALU(Instruction_to_ALU),
    .imm(imm),
    .rd(rd),
    .rs1(rs1),
    .rs2(rs2),
    .shamt(shamt),
    .pc_increment(pc_increment),
    .pipeline_override(pipeline_override),
    .invalid_instruction(invalid_instruction)
);

endmodule
