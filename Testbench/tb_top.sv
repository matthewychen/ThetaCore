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
    reg [2:0] ALU_opcode;
    reg ALU_opcode_differentiator;
    reg ALU_optype;
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
        ALU_opcode = 3'b000;
        ALU_opcode_differentiator = 1'b0;
        ALU_optype = 1'b0;
        Instruction_to_ALU = 5'd16; // Invalid instruction initially
        test_case = 0;
        
        // Reset sequence
        #20 reset = 0;
        #10;
        
        // Test all 16 ALU operations
        test_alu_operation(5'd6, "ADD", 32'h00000005, 32'h00000003);
        test_alu_operation(5'd7, "SUB", 32'h00000005, 32'h00000003);
        test_alu_operation(5'd8, "SLL", 32'h00000003, 32'h00000002);
        test_alu_operation(5'd9, "SLT", 32'h00000003, 32'h00000005);
        test_alu_operation(5'd10, "SLTU", 32'hFFFFFFFF, 32'h00000001);
        test_alu_operation(5'd11, "XOR", 32'h0F0F0F0F, 32'hFF00FF00);
        test_alu_operation(5'd12, "SRL", 32'hF0000000, 32'h00000004);
        test_alu_operation(5'd13, "SRA", 32'hF0000000, 32'h00000004);
        test_alu_operation(5'd14, "OR", 32'h0F0F0F0F, 32'hFF00FF00);
        test_alu_operation(5'd15, "AND", 32'h0F0F0F0F, 32'hFF00FF00);
        
        // Branch comparison tests
        test_alu_operation(5'd0, "BEQ", 32'h00000005, 32'h00000005);
        test_alu_operation(5'd1, "BNE", 32'h00000005, 32'h00000003);
        test_alu_operation(5'd2, "BLT", 32'hFFFFFFFD, 32'h00000000); // -3 < 0
        test_alu_operation(5'd3, "BGE", 32'h00000000, 32'hFFFFFFFD); // 0 >= -3
        test_alu_operation(5'd4, "BLTU", 32'h00000003, 32'h00000005);
        test_alu_operation(5'd5, "BGEU", 32'h00000005, 32'h00000003);
        
        #50 $display("All ALU tests completed");
        $finish;
    end
    
    //-------------------------------
    // Test task
    //-------------------------------
    task test_alu_operation;
        input [4:0] instr;
        input string op_name;
        input [31:0] operand1;
        input [31:0] operand2;
    begin
        test_case = test_case + 1;
        test_name = op_name;
        
        // Apply test inputs
        @(posedge soc_clk);
        Instruction_to_ALU = instr;
        ALU_dat1 = operand1;
        ALU_dat2 = operand2;
        dat_ready = 1;
        
        // Wait for operation to complete (4 clock cycles)
        repeat(4) @(posedge soc_clk);
        
        // Display results
        $display("\n----- Test Case %0d: %s -----", test_case, test_name);
        $display("Inputs: A = 0x%h, B = 0x%h", operand1, operand2);
        $display("Result: 0x%h", ALU_out);
        
        if (ALU_overflow)
            $display("Overflow flag set");
        
        if (ALU_zero)
            $display("Zero flag set");
            
        if (ALU_con_met)
            $display("Condition met flag set");
            
        // Deassert data ready and wait
        dat_ready = 0;
        #20;
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
        .ALU_opcode(ALU_opcode),
        .ALU_opcode_differentiator(ALU_opcode_differentiator),
        .ALU_optype(ALU_optype),
        .Instruction_to_ALU(Instruction_to_ALU),
        .ALU_overflow(ALU_overflow),
        .ALU_con_met(ALU_con_met),
        .ALU_zero(ALU_zero),
        .ALU_err(ALU_err),
        .ALU_ready(ALU_ready),
        .ALU_out(ALU_out)
    );
    
endmodule