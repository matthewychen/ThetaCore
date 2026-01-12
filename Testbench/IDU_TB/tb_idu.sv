/// NO LONGER WORKS DUE TO MOVING STAGE COUNTER TO CU. need to generate new stimulus with using new instantiation


`timescale 1ns/1ps

module tb_idu;

    //----------------------------------------------------------------
    // Signal Declarations
    //----------------------------------------------------------------
    reg soc_clk;
    reg IDU_reset;
    reg [31:0] instruction;

    // Outputs from DUT
    wire [4:0] Instruction_to_ALU;
    wire [5:0] Instruction_to_CU;
    wire [31:0] imm;
    wire [4:0] rd;
    wire [4:0] rs1;
    wire [4:0] rs2;
    wire [4:0] shamt;
    wire [31:0] pc_increment;
    wire invalid_instruction;
    reg [1:0] stage_counter;

    // Testbench variables
    integer tests_passed = 0;
    integer tests_failed = 0;

    //----------------------------------------------------------------
    // DUT Instantiation
    //----------------------------------------------------------------
    IDU_top DUT (
        .soc_clk(soc_clk),
        .IDU_reset(IDU_reset),
        .instruction(instruction),
        .stage_counter(stage_counter),
        .Instruction_to_CU(Instruction_to_CU),
        .imm(imm),
        .rd(rd),
        .rs1(rs1),
        .rs2(rs2),
        .shamt(shamt),
        .pc_increment(pc_increment),
        .invalid_instruction(invalid_instruction)
    );

    //----------------------------------------------------------------
    // Clock Generation
    //----------------------------------------------------------------
    initial begin
        soc_clk = 0;
        forever #5 soc_clk = ~soc_clk; // 100MHz
    end

    //----------------------------------------------------------------
    // Test Task
    //----------------------------------------------------------------
    task check_op;
        input string name;
        input [31:0] instr_in;
        input [5:0] exp_cu_op;
        input [4:0] exp_rd;
        input [4:0] exp_rs1;
        input [4:0] exp_rs2;
        input [31:0] exp_imm;
        input check_imm; // 1 to check imm, 0 to expect Z
    begin
        // 1. Apply Instruction
        instruction = instr_in;
        
        // 2. Wait for IDU State Machine
        // Cycle 0: Receive (Counter 0)
        // Cycle 1: Broad Decode (Counter 1)
        // Cycle 2: Specific Decode & Output (Counter 2) -> Check here
        
        // Wait 2 clock edges to get to state 2 logic
        repeat(2) @(posedge soc_clk);
        
        // Allow combinatorial logic to settle after the 2nd edge
        #1; 

        // 3. Verify Outputs
        if (Instruction_to_CU === exp_cu_op &&
            rd === exp_rd &&
            rs1 === exp_rs1 &&
            (rs2 === exp_rs2) && // Use === for Z comparison
            (!check_imm || imm === exp_imm)) begin
            
            $display("[PASS] %s | Inst: %h | CU_OP: %d", name, instr_in, Instruction_to_CU);
            tests_passed++;
        end else begin
            $display("[FAIL] %s | Inst: %h", name, instr_in);
            if (Instruction_to_CU !== exp_cu_op) $display("\tExp CU: %d, Got: %d", exp_cu_op, Instruction_to_CU);
            if (rd !== exp_rd) $display("\tExp RD: %h, Got: %h", exp_rd, rd);
            if (rs1 !== exp_rs1) $display("\tExp RS1: %h, Got: %h", exp_rs1, rs1);
            if (rs2 !== exp_rs2) $display("\tExp RS2: %h, Got: %h", exp_rs2, rs2);
            if (check_imm && imm !== exp_imm) $display("\tExp IMM: %h, Got: %h", exp_imm, imm);
            tests_failed++;
        end

        // Wait for cycle 3 (No Op) and wrap around
        repeat(2) @(posedge soc_clk);
    end
    endtask

    //----------------------------------------------------------------
    // Main Test Sequence
    //----------------------------------------------------------------
    // Drive stage_counter synchronously; avoid zero-delay forever loops
    always @(posedge soc_clk or posedge IDU_reset) begin
        if (IDU_reset) begin
            stage_counter <= 0;
        end else begin
            stage_counter <= stage_counter + 1;
        end
    end
    
    initial begin
        // Initialize
        IDU_reset = 1;
        instruction = 0;
        #20;
        IDU_reset = 0;
        #10;

        $display("=== Starting IDU Verification ===");

        // --- Type 0: LUI (CU Code 0) ---
        // LUI x1, 0x12345 -> Imm=0x12345000
        check_op("LUI", 32'h123450B7, 6'd0, 5'd1, 5'bz, 5'bz, 32'h12345000, 1);

        // --- Type 1: AUIPC (CU Code 1) ---
        // AUIPC x2, 0x10000
        check_op("AUIPC", 32'h10000117, 6'd1, 5'd2, 5'bz, 5'bz, 32'h10000000, 1);

        // --- Type 2: JAL (CU Code 2) ---
        // JAL x1, offset -> J-Type
        // 000000000001 00000 000 00001 1101111 (JAL x1, 1) -> Imm decoding is complex
        check_op("JAL", 32'h001000EF, 6'd2, 5'd1, 5'bz, 5'bz, 32'h0, 0); // Imm is 0 in your code for JAL

        // --- Type 3: JALR (CU Code 3) ---
        // JALR x1, x2, 0
        check_op("JALR", 32'h000100E7, 6'd3, 5'd1, 5'd2, 5'bz, 32'h0, 1);

        // --- Type 4: Branch (BEQ - CU Code 4) ---
        // BEQ x1, x2, offset
        check_op("BEQ", 32'h00208063, 6'd4, 5'bz, 5'd1, 5'd2, 32'h0, 0); // Checking op/regs only

        // --- Type 5: Store (SW - CU Code 12) ---
        // SW x2, 0(x1) -> funct3=010
        check_op("SW", 32'h0020A023, 6'd12, 5'bz, 5'd1, 5'd2, 32'h0, 1);

        // --- Type 6: Load (LW - CU Code 15) ---
        // LW x1, 0(x2) -> funct3=010
        check_op("LW", 32'h00012083, 6'd15, 5'd1, 5'd2, 5'bz, 32'h0, 1);

        // --- Type 7: Calc Imm (ADDI - CU Code 18) ---
        // ADDI x1, x2, 1 -> funct3=000
        check_op("ADDI", 32'h00110093, 6'd18, 5'd1, 5'd2, 5'bz, 32'h1, 1);

        // --- Type 8: Register (ADD - CU Code 27) ---
        // ADD x1, x2, x3 -> funct3=000, funct7=0000000
        check_op("ADD", 32'h003100B3, 6'd27, 5'd1, 5'd2, 5'd3, 32'bz, 0);

        // --- Type 8: Register (SUB - CU Code 28) ---
        // SUB x1, x2, x3 -> funct3=000, funct7=0100000
        check_op("SUB", 32'h403100B3, 6'd28, 5'd1, 5'd2, 5'd3, 32'bz, 0);

        // --- Type 9: FENCE (CU Code 37) ---
        check_op("FENCE", 32'h0000000F, 6'd37, 5'bz, 5'bz, 5'bz, 32'bz, 0);

        // --- Type 10: ECALL (CU Code 39) ---
        // Note: This might fail or behave oddly due to the 'instruction = 0' bug in DUT
        check_op("ECALL", 32'h00000073, 6'd39, 5'bz, 5'bz, 5'bz, 32'bz, 0);

        $display("==================================");
        $display("Tests Passed: %d", tests_passed);
        $display("Tests Failed: %d", tests_failed);
        $display("==================================");
        $finish;
    end

    //----------------------------------------------------------------
    // Waveform Generation
    //----------------------------------------------------------------
    initial begin
        $dumpfile("idu_wave.vcd"); // Specifies the output file name
        $dumpvars(0, tb_idu);
    end

endmodule