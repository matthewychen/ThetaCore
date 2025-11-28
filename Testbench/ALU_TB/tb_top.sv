`include "defines.vh"

module tb_alu;
    //-------------------------------
    // Signal declarations
    //-------------------------------
    reg soc_clk;
    reg reset;
    reg dat_ready;
    reg [31:0] ALU_dat1;
    reg [31:0] ALU_dat2;
    reg [4:0] Instruction_to_ALU;
    
    // Output signals
    wire ALU_overflow;
    wire ALU_con_met;
    wire ALU_zero;
    wire ALU_err;
    wire ALU_ready;
    wire [31:0] ALU_out;

    // Test control variables
    integer test_case;
    string test_name;
    integer timeout;
    
    // Test statistics
    integer tests_passed;
    integer tests_failed;
    
    //-------------------------------
    // Clock generation
    //-------------------------------
    initial begin
        soc_clk = 0;
        forever #5 soc_clk = ~soc_clk; // 100MHz clock
    end

    //-------------------------------
    // Waveform generation
    //-------------------------------
    initial begin
        $dumpfile("alu_wave.vcd");
        $dumpvars(0, tb_alu);
        $display("ALU Test - Compilation Success!");
        
        // Initialize test counters
        tests_passed = 0;
        tests_failed = 0;
    end

    //-------------------------------
    // Test sequence
    //-------------------------------
    initial begin
        // Initialize signals
        reset = 1;
        dat_ready = 0;
        ALU_dat1 = 32'h0;
        ALU_dat2 = 32'h0;
        Instruction_to_ALU = 5'd16; // Invalid instruction initially
        test_case = 0;
        
        // Reset sequence
        #20 reset = 0;
        #10;
        
        // Test all ALU operations with expected results
        test_alu_operation(5'd6, "ADD", 32'h00000005, 32'h00000003, 32'h00000008, 1'b0, 1'b0, 1'b0);
        test_alu_operation(5'd7, "SUB", 32'h00000005, 32'h00000003, 32'h00000002, 1'b0, 1'b0, 1'b0);
        test_alu_operation(5'd8, "SLL", 32'h00000003, 32'h00000002, 32'h0000000c, 1'b0, 1'b0, 1'b0);
        test_alu_operation(5'd9, "SLT", 32'h00000003, 32'h00000005, 32'h00000001, 1'b0, 1'b0, 1'b1);
        test_alu_operation(5'd10, "SLTU", 32'hFFFFFFFF, 32'h00000001, 32'h00000000, 1'b0, 1'b0, 1'b0);
        test_alu_operation(5'd11, "XOR", 32'h0F0F0F0F, 32'hFF00FF00, 32'hF00FF00F, 1'b0, 1'b0, 1'b0);
        test_alu_operation(5'd12, "SRL", 32'hF0000000, 32'h00000004, 32'h0F000000, 1'b0, 1'b0, 1'b0);
        test_alu_operation(5'd13, "SRA", 32'hF0000000, 32'h00000004, 32'hFF000000, 1'b0, 1'b0, 1'b0);
        test_alu_operation(5'd14, "OR", 32'h0F0F0F0F, 32'hFF00FF00, 32'hFF0FFF0F, 1'b0, 1'b0, 1'b0);
        test_alu_operation(5'd15, "AND", 32'h0F0F0F0F, 32'hFF00FF00, 32'h0F000F00, 1'b0, 1'b0, 1'b0);
        
        // Branch comparison tests
        test_alu_operation(5'd0, "BEQ", 32'h00000005, 32'h00000005, 32'h00000000, 1'b0, 1'b0, 1'b1);
        test_alu_operation(5'd1, "BNE", 32'h00000005, 32'h00000003, 32'h00000000, 1'b0, 1'b0, 1'b1);
        test_alu_operation(5'd2, "BLT", 32'hFFFFFFFD, 32'h00000000, 32'h00000000, 1'b0, 1'b0, 1'b1);
        test_alu_operation(5'd3, "BGE", 32'h00000000, 32'hFFFFFFFD, 32'h00000000, 1'b0, 1'b0, 1'b1);
        test_alu_operation(5'd4, "BLTU", 32'h00000003, 32'h00000005, 32'h00000000, 1'b0, 1'b0, 1'b1);
        test_alu_operation(5'd5, "BGEU", 32'h00000005, 32'h00000003, 32'h00000000, 1'b0, 1'b0, 1'b1);
        
        // Display test summary
        #50;
        $display("\n===== ALU TEST SUMMARY =====");
        $display("Total tests:      %0d", tests_passed + tests_failed);
        $display("Tests passed:     %0d", tests_passed);
        $display("Tests failed:     %0d", tests_failed);
        $display("Success rate:     %0.1f%%", (tests_passed * 100.0) / (tests_passed + tests_failed));
        $display("===========================");
        
        if (tests_failed == 0) begin
            $display("ALL TESTS PASSED SUCCESSFULLY!");
        end else begin
            $display("SOME TESTS FAILED! Review the test log for details.");
        end
        
        $finish;
    end
    
    //-------------------------------
    // Test task - With expected outputs
    //-------------------------------
    task test_alu_operation;
        input [4:0] instr;
        input string op_name;
        input [31:0] operand1;
        input [31:0] operand2;
        input [31:0] expected_result;
        input expected_overflow;
        input expected_zero;
        input expected_con_met;
        bit test_passed;
    begin
        test_case = test_case + 1;
        test_name = op_name;
        test_passed = 1'b1;
        
        // Make sure we wait a full 4 clock cycles from previous test
        //repeat(4) @(posedge soc_clk);
        
        // Apply test inputs
        @(posedge soc_clk);
        Instruction_to_ALU = instr;
        ALU_dat1 = operand1;
        ALU_dat2 = operand2;
        dat_ready = 1;
        
        // Wait exactly 4 clock cycles for the operation
        repeat(3) @(posedge soc_clk);
        
        // Display results
        $display("\n----- Test Case %0d: %s -----", test_case, test_name);
        $display("Inputs: A = 0x%h, B = 0x%h", operand1, operand2);
        $display("Result: 0x%h (Expected: 0x%h)", ALU_out, expected_result);
        
        // Check results against expected values
        if (ALU_out !== expected_result) begin
            $display("ERROR: Result mismatch! Expected: 0x%h, Got: 0x%h", expected_result, ALU_out);
            test_passed = 1'b0;
        end
        
        if (ALU_overflow !== expected_overflow) begin
            $display("ERROR: Overflow flag mismatch! Expected: %0d, Got: %0d", expected_overflow, ALU_overflow);
            test_passed = 1'b0;
        end
        
        if (ALU_zero !== expected_zero) begin
            $display("ERROR: Zero flag mismatch! Expected: %0d, Got: %0d", expected_zero, ALU_zero);
            test_passed = 1'b0;
        end
        
        if (ALU_con_met !== expected_con_met) begin
            $display("ERROR: Condition met flag mismatch! Expected: %0d, Got: %0d", expected_con_met, ALU_con_met);
            test_passed = 1'b0;
        end
        
        // Display flag status
        if (ALU_overflow)
            $display("Overflow flag set");
        
        if (ALU_zero)
            $display("Zero flag set");
            
        if (ALU_con_met)
            $display("Condition met flag set");
            
        // Update test statistics
        if (test_passed) begin
            tests_passed = tests_passed + 1;
            $display("TEST PASSED");
        end else begin
            tests_failed = tests_failed + 1;
            $display("TEST FAILED");
        end
        
        // Deassert data ready and wait for ALU to process this change
        dat_ready = 0;
    end
    endtask

    //-------------------------------
    // ALU instantiation
    //-------------------------------
    ALU_top ALU_DUT(
        .soc_clk(soc_clk),
        .reset(reset),
        .dat_ready(dat_ready),
        .ALU_dat1(ALU_dat1),
        .ALU_dat2(ALU_dat2),
        .Instruction_to_ALU(Instruction_to_ALU),
        .ALU_overflow(ALU_overflow),
        .ALU_con_met(ALU_con_met),
        .ALU_zero(ALU_zero),
        .ALU_err(ALU_err),
        .ALU_ready(ALU_ready),
        .ALU_out(ALU_out)
    );
    
endmodule