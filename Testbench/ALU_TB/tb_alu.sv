`timescale 1ns/1ps

module tb_alu;

    //----------------------------------------------------------------
    // Signal Declarations
    //----------------------------------------------------------------
    reg soc_clk;
    reg reset;
    reg dat_ready;
    reg [31:0] ALU_dat1;
    reg [31:0] ALU_dat2;
    reg [5:0] Instruction_from_CU;

    wire ALU_overflow;
    wire ALU_con_met;
    wire ALU_zero;
    wire ALU_err;
    wire ALU_ready;
    wire [31:0] ALU_out;

    //----------------------------------------------------------------
    // DUT Instantiation
    //----------------------------------------------------------------
    ALU_top dut (
        .soc_clk(soc_clk),
        .reset(reset),
        .dat_ready(dat_ready),
        .ALU_dat1(ALU_dat1),
        .ALU_dat2(ALU_dat2),
        .Instruction_from_CU(Instruction_from_CU),
        .ALU_overflow(ALU_overflow),
        .ALU_con_met(ALU_con_met),
        .ALU_zero(ALU_zero),
        .ALU_err(ALU_err),
        .ALU_ready(ALU_ready),
        .ALU_out(ALU_out)
    );

    //----------------------------------------------------------------
    // Clock Generation
    //----------------------------------------------------------------
    initial begin
        soc_clk = 0;
        forever #5 soc_clk = ~soc_clk;
    end

    //----------------------------------------------------------------
    // Waveform Dumping
    //----------------------------------------------------------------
    initial begin
        $dumpfile("alu_wave.vcd");
        $dumpvars(0, tb_alu);
    end

    //----------------------------------------------------------------
    // Test Sequence
    //----------------------------------------------------------------
    initial begin
        $display("Starting ALU Testbench...");

        // 1. Reset the DUT
        reset = 1;
        dat_ready = 0;
        ALU_dat1 = 0;
        ALU_dat2 = 0;
        Instruction_from_CU = 0;
        @(posedge soc_clk);
        @(posedge soc_clk);
        reset = 0;
        @(posedge soc_clk);
        $display("Reset complete.");

        // Format: testsequence(Name, In1, In2, OpCode, ExpOut, ExpZero, ExpOvf, ExpConMet);

        // --- Arithmetic ---
        // ADD: 10 + 5 = 15
        testsequence("ADD (10+5)",   32'd10, 32'd5, 6'd27, 32'd15, 0, 0, 0);
        
        // SUB: 10 - 5 = 5
        testsequence("SUB (10-5)",   32'd10, 32'd5, 6'd28, 32'd5,  0, 0, 0);
        
        // SUB: 5 - 10 = -5 (0xFFFFFFFB)
        testsequence("SUB (5-10)",   32'd5, 32'd10, 6'd28, 32'hFFFF_FFFB, 0, 0, 0);

        // --- Shifts ---
        // SLL: 1 << 2 = 4
        testsequence("SLL (1<<2)",   32'd1, 32'd2, 6'd29, 32'd4, 0, 0, 0);
        
        // SRL: 8 >> 2 = 2
        testsequence("SRL (8>>2)",   32'd8, 32'd2, 6'd33, 32'd2, 0, 0, 0);
        
        // SRA: -8 >>> 2 = -2 (0xFFFFFFFE)
        testsequence("SRA (-8>>>2)", 32'hFFFF_FFF8, 32'd2, 6'd34, 32'hFFFF_FFFE, 0, 0, 0);

        // --- Logical ---
        // XOR: F0 ^ 0F = FF
        testsequence("XOR (F0^0F)",  32'hF0, 32'h0F, 6'd32, 32'hFF, 0, 0, 0);
        
        // OR: F0 | 0F = FF
        testsequence("OR  (F0|0F)",  32'hF0, 32'h0F, 6'd35, 32'hFF, 0, 0, 0);
        
        // AND: F0 & 0F = 00
        testsequence("AND (F0&0F)",  32'hF0, 32'h0F, 6'd36, 32'h00, 1, 0, 0);

        // --- Set Less Than ---
        // SLT (Signed): -1 < 10 -> True (1)
        testsequence("SLT (-1 < 10)", 32'hFFFF_FFFF, 32'd10, 6'd30, 32'd1, 0, 0, 0);
        
        // SLTU (Unsigned): -1 (MaxUint) < 10 -> False (0)
        testsequence("SLTU (-1 < 10)", 32'hFFFF_FFFF, 32'd10, 6'd31, 32'd0, 1, 0, 0);

        // --- Branches ---
        // BEQ: 5 == 5 -> Met
        testsequence("BEQ (5==5)",    32'd5, 32'd5, 6'd4, 32'd0, 1, 0, 1);
        
        // BNE: 5 != 4 -> Met
        testsequence("BNE (5!=4)",    32'd5, 32'd4, 6'd5, 32'd0, 1, 0, 1);
        
        // BLT: -5 < 5 -> Met
        testsequence("BLT (-5<5)",   32'hFFFF_FFFB, 32'd5, 6'd6, 32'd0, 1, 0, 1);
        
        // BGE: 5 >= -5 -> Met
        testsequence("BGE (5>=-5)",   32'd5, 32'hFFFF_FFFB, 6'd7, 32'd0, 1, 0, 1);
        
        // BLTU: 10 < 20 -> Met
        testsequence("BLTU (10<20)",  32'd10, 32'd20, 6'd8, 32'd0, 1, 0, 1);
        
        // BGEU: 20 >= 10 -> Met
        testsequence("BGEU (20>=10)", 32'd20, 32'd10, 6'd9, 32'd0, 1, 0, 1);

        $display("Testbench finished.");
        $finish;
    end

    //----------------------------------------------------------------
    // Test Task
    //----------------------------------------------------------------
    // Note: Using reg [255:0] for name to be compatible with standard Verilog
task testsequence;
    input [8*32-1:0] name; 
    input [31:0] in1;
    input [31:0] in2;
    input [5:0] instr;
    input [31:0] exp_out;
    input exp_zero;
    input exp_ovf;
    input exp_con;
    
    begin
        // 1. Drive inputs
        ALU_dat1 = in1;
        ALU_dat2 = in2;
        Instruction_from_CU = instr;

        // 2. WAIT a cycle so inputs are stable
        @(posedge soc_clk);

        // 3. Handshake: pulse dat_ready
        dat_ready = 1;
        @(posedge soc_clk);
        dat_ready = 0;

        // 4. Wait for result
        while (!ALU_ready)
            @(posedge soc_clk);

        // 5. Check results
        if (ALU_out !== exp_out ||
            ALU_zero !== exp_zero ||
            ALU_overflow !== exp_ovf ||
            ALU_con_met !== exp_con) begin

            $display("ERROR: %0s FAILED", name);
            $display("  Inputs: A=%h, B=%h, Instr=%d", in1, in2, instr);
            $display("  Expected: Out=%h, zeroflag=%b, overflow=%b, condition=%b",
                     exp_out, exp_zero, exp_ovf, exp_con);
            $display("  Actual:   Out=%h, zeroflag=%b, overflow=%b, condition=%b",
                     ALU_out, ALU_zero, ALU_overflow, ALU_con_met);
        end else begin
            $display("PASS: %0s", name);
        end

        // 6. Cooldown
        repeat (2) @(posedge soc_clk);
    end
endtask


endmodule