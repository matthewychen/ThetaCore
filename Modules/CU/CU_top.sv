module CU_top(
    //templated
    input soc_clk,
    input poweron

    //instantiation of ALU
    //module to handle flag from branch command,
    //32x general purpose registers, special registers PC (needs to be able to handle jal/jalr), IR, MDR, MAR, TEMP. dont use sram, just use builtin... sram is too much of a headache and would add additional lag
    //pipelining override #################### important dont forget. use signal from IDU_top
    //branch command handler:
    //on negedge

    //$finish on posedge any error, ecall, or ebreak.

    //for JALR and JAL, make sure to stall and wait for those instructions to finish before proceeding

);

reg [31:0] Cu_PC; //if PC > 4*128: kill
reg [31:0] Cu_IR; //collect from memfetch at some point
reg [31:0] Cu_MDR;
reg [31:0] Cu_MAR;
reg [31:0] Cu_TEMP; //needed to save offset/return address for branch prediction.

reg [31:0][31:0] CU_reg;
//31 general purpose registers and the zero register - x0 - x31        | Application_Binary_Interface Name
// reg_00: 0 reg                                                       | zero
// reg_01: return address                                              | ra
// reg_02: stack pointer                                               | sp
// reg_03: global pointer                                              | gp
// reg_04: thread pointer. Will not implement (long explanation.)      | tp
// reg_05: temp reg 0                                                  | t0
// reg_06: temp reg 1                                                  | t1
// reg_07: temp reg 2                                                  | t2
// reg_08: saved reg 0 /frame pointer                                  | s0/fp
// reg_09: saved reg 1                                                 | s1
// reg_10: function arg 0                                              | a0
// reg_11: function arg 1                                              | a1
// reg_12: function arg 2                                              | a2
// reg_13: function arg 3                                              | a3
// reg_14: function arg 4                                              | a4
// reg_15: function arg 5                                              | a5
// reg_16: function arg 6                                              | a6
// reg_17: function arg 7                                              | a7
// reg_18: saved reg 2                                                 | s2
// reg_19: saved reg 3                                                 | s3
// reg_20: saved reg 4                                                 | s4
// reg_21: saved reg 5                                                 | s5 
// reg_22: saved reg 6                                                 | s6 
// reg_23: saved reg 7                                                 | s7 
// reg_24: saved reg 8                                                 | s8 
// reg_25: saved reg 9                                                 | s9
// reg_26: saved reg 10                                                | s10
// reg_27: saved reg 11                                                | s11
// reg_28: temp reg 3                                                  | t3
// reg_29: temp reg 4                                                  | t4
// reg_30: temp reg 5                                                  | t5
// reg_31: temp reg 6                                                  | t6

//from IDU
reg [5:0] Instruction_to_CU;
reg [4:0] Instruction_to_ALU; //needs to be outputted to ALU 1 clock cycle before dat_ready
//databusses
reg [31:0] imm;
reg [4:0] rd; //CU register sel
reg [4:0] rs1;
reg [4:0] rs2;
reg [4:0] shamt;
reg [31:0] pc_increment;

always@(posedge poweron) begin //instantiate everything to 0. Poweron sequence.
    CU_result_counter = 2'b11;
    memfetch_start = 0;
    IF_reset <= 1'b0;    
    ID_reset <= 1'b0;
    EX_reset <= 1'b0;
    MEM_reset <= 1'b0;
    WB_reset <= 1'b0;
    poweron_state <= JUSTON;
end

always@(posedge soc_clk) begin
        if(CU_result_counter == 0) begin //all ready signals should be asserted here
            //query for memory read
            //memfetch should assert Fetch_ready to IDU, IDU should begin decryption now
            //decode IDU_result
            CU_result_counter = CU_result_counter + 1;
        end
        else if(CU_result_counter == 1) begin
            // begin setting outputs to child modules
            // collect decoded from IDU: use this to:
            // evaluate branch/override condition
            CU_result_counter = CU_result_counter + 1;
        end
        else if(CU_result_counter == 2) begin
            //check pipelining from IDU; perform rs1 override if nessessary on ALU inputs
            //set all other ALU inputs, including Instruction_to_ALU
            CU_result_counter = CU_result_counter + 1;
        end
        else if(CU_result_counter == 3) begin
            //CU_ready to ALU
            //Increment PC.
            //conclude cycle
            //CU_result_counter = 0; DONT reset as this will shorten the stage length to 3 instead of 4. should overflow automatically
            CU_result_counter = CU_result_counter + 1;
        end
end

// ----------- WB MODULE ----------- //

always@(posedge soc_clk) begin
end






















//ERROR CATCH BLOCK
always@(posedge ALU_err or posedge invalid_instruction) begin //include other errors as they come
    $finish;
end

// Inside CU_top module
CU_ID instruction_decoder(
    .soc_clk(soc_clk),
    .reset(reset),
    .decode_start(decode_start),    // From MMU or other control signal
    .IDU_stall(IDU_stall),          // Connect to hazard detection
    .Cu_IR(Cu_IR),                  // Connect to instruction register
    
    // Connect all outputs to CU internal signals
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