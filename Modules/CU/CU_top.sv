module ControlUnit(
    //templated
    input soc_clk

    //instantiation of ALU
    //module to handle flag from branch command,
    //32x general purpose registers, special registers PC (needs to be able to handle jal/jalr), IR, MDR, MAR, TEMP. dont use sram, just use builtin... sram is too much of a headache and would add additional lag
    //pipelining override #################### important dont forget. use signal from IDU_top
    //branch command handler:
    //on negedge

    //$finish on posedge any error, ecall, or ebreak.

    //for JALR and JAL, make sure to stall and wait for those instructions to finish before proceeding

);
//GLOBAL RESET/FLUSH
reg reset;

reg [1:0] CU_result_counter; //actually needed in CU to implement pipelining override and coordinate various activities.

reg [31:0] Cu_PC; //if PC > 4*128: kill
reg [31:0] Cu_IR; //collect from memfetch at some point
reg [31:0] Cu_MDR;
reg [31:0] Cu_MAR;
reg [31:0] Cu_TEMP; //needed?
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

//from IDU
reg IDU_ready;
reg [5:0] Instruction_to_CU;
reg [4:0] Instruction_to_ALU; //needs to be outputted to ALU 1 clock cycle before dat_ready
//databusses
reg [31:0] imm;
reg [4:0] rd; //CU register sel
reg [4:0] rs1;
reg [4:0] rs2;
reg [4:0] shamt;
reg [31:0] pc_increment;

//flags
reg [1:0] pipeline_override;
    //00 -> no override on next instruction
    //01 -> override rs1
    //10 -> override rs2

reg memfetch_start;
reg decode_start;
reg last_branch_state; //for simple branch prediction

initial begin //instantiate everything to 0.
    CU_result_counter = 0;
    memfetch_start = 0;
end

always@(posedge soc_clk) begin
    else if(CU_result_counter == 0) begin //all ready signals should be asserted here
        //query for memory read
        //memfetch should assert Fetch_ready to IDU, IDU should begin decryption now
        //decode IDU_result
        //If 
        CU_result_counter = CU_result_counter + 1;
    end
    else if(CU_result_counter == 1) begin
        // begin setting outputs to child modules
        // collect decoded from IDU: use this to:
        // evaluate branch condition
        CU_result_counter = CU_result_counter + 1;
    end
    else if(CU_result_counter == 2) begin
        //check pipelining from IDU; perform rs1 override if nessessary on ALU inputs
        //set all other ALU inputs, including Instruction_to_ALU
        CU_result_counter = CU_result_counter + 1;
    end
    else if(CU_result_counter == 3) begin
        //CU_ready to ALU. 
        //Increment PC.
        //conclude cycle
        //CU_result_counter = 0; DONT reset as this will shorten the stage length to 3 instead of 4. should overflow automatically
        CU_result_counter = CU_result_counter + 1;
    end
end

always@(posedge ALU_err or posedge invalid_instruction) begin
    $finish;
end

mem_interface mem_interface_unit(
    soc_clk,
    .reset(reset),
    .CU_ready(memfetch_start),
    .CU_IR(CU_IR)
    .bits_to_access(),
    .read_or_write()
);

IDU_top instruction_decode_unit(
    .soc_clk(soc_clk),
    .reset(reset),
    .Fetch_ready(decode_start),  // Assuming Fetch_ready is available in CU
    .instruction(Cu_IR),        // Using CU_IR as the instruction input
    
    // IDU outputs to CU
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
    .invalid_instruction(invalid_instruction)  // This will need to be declared in CU
);

endmodule