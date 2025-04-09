module IDU_top(
    //templated
    input soc_clk,
    input reset,
    input [31:0] instruction,
    input Fetch_ready,

    output IDU_ready, //CU read cue
    output [4:0] Instruction_to_ALU, //ALU instruction select, only driven if relevant, otherwise left at invalid = 5'd16
    output [3:0] ALU_module_select, //one-hot
        //4'b0001 -> Addsub
        //4'b0010 -> Comparator
        //4'b0100 -> Logop
        //4'b1000 -> Shifter
    output [7:0] Instruction_to_CU, //CU instruction select, superset of ALU_module
    

    //databusses
    output reg [31:0] imm,
    output reg [4:0] rd, //CU register sel
    output reg [4:0] rs1,
    output reg [4:0] rs2,
    output reg [4:0] shamt,

    //flags
    output reg [1:0] pipeline_override;
    //00 -> no override
    //01 -> override rs1
    //10 -> override rs2
    output reg invalid_instruction;
);

    reg [3:0] decryptedOPtype;
    //0  -> LUI U
    //1  -> AUIPC U
    //2  ->  JAL J
    //3  -> JALR J
    //4  -> B
    //5  -> S
    //6  -> IG1 (load)
    //7  -> IG2 (calc)
    //8  -> R
    //9  -> ecall/ebreak
    //10 -> invalid
    //11 -> initial

    initial begin
        decryptedOPtype <= 11;
        imm <= 32'bz;
        rd <= 5'bz;
        rs1 <= 5'bz;
        rs2 <= 5'bz;
        shamt <= 5'bz;

        IDU_ready <= 0;
        Instruction_to_ALU <= 16;
        ALU_module_select <= 0;
        Instruction_to_CU <= 0;

        invalid_instruction <= 0;
        pipeline_override <= 0;

        reg_instruction <= 0;
        //set all output regs to 0
    end

    //save instruction in register
    reg [31:0] reg_instruction;
    always@posedge(Fetch_ready) begin
        reg_instruction <= instruction;
    end

    always@(reg_instruction) begin //update optype
        casez(reg_instruction[6:0]) //note use of caseZ
            7'b0110111: decryptedOPtype = 0;
            7'b0010111: decryptedOPtype = 1;

            7'b1101111: decryptedOPtype = 2;
            7'b1100111: decryptedOPtype = 3;

            7'b1100011: decryptedOPtype = 4;
            7'b0100011: decryptedOPtype = 5;

            7'b0000011: decryptedOPtype = 6;
            7'b0010011: decryptedOPtype = 7;
            7'b0110011: decryptedOPtype = 8;

            7'b1110011: decryptedOPtype = 9; //ecall/ebreak

            default: decryptedOPtype = 10; //error case
        endcase
    end

    always@(decryptedOPtype or reset) begin
        if(decryptedOPtype==0) begin
        end
        else if(decryptedOPtype==1) begin
        end
        else if(decryptedOPtype==2) begin
        end
        else if(decryptedOPtype==3) begin
        end
        else if(decryptedOPtype==4) begin
        end
        else if(decryptedOPtype==5) begin
        end
        else if(decryptedOPtype==6) begin
        end
        else if(decryptedOPtype==7) begin
        end
        else if(decryptedOPtype==8) begin
        end
        else if(decryptedOPtype==9) begin
        end
        else if(decryptedOPtype==10) begin
            //set all outputs to 0 and error flag
        end
        else if(decryptedOPtype==11) begin //null case as no decryption has happened yet
            //empty
        end
        else begin //10 case included, all invalid cases/decryption errors
            decryptedOPtype <= 11;
            imm <= 0;
            rd <= 0;
            rs1 <= 0;
            rs2 <= 0;
            shamt <= 0;

            IDU_ready <= 0;
            Instruction_to_ALU <= 16;
            ALU_module_select <= 0;
            Instruction_to_CU <= 0;

            invalid_instruction <= 1;
            pipeline_override <= 0;
            //set all outputs to 0
        end
    end

    //specific instructions for ALU
    always@(posedge IDU_ready) begin 
        casez(does not work anymore need to replace)

            //B
            5'b10000: Instruction_to_ALU = 5'd0; //BEQ branch equal
            5'b10001: Instruction_to_ALU = 5'd1; //BNE branch not equal
            5'b10100: Instruction_to_ALU = 5'd2; //BLT branch less than
            5'b10101: Instruction_to_ALU = 5'd3; //BGE branch greater than or equal
            5'b10110: Instruction_to_ALU = 5'd4; //BLTU branch less than unsigned
            5'b10111: Instruction_to_ALU = 5'd5; //BGEU branch greater than or equal unsigned

            //I/R
            5'b00000: Instruction_to_ALU = 5'd6; //ADD/ADDI add 
            5'b01000: Instruction_to_ALU = 5'd7; //SUB subtract 
            5'b00001: Instruction_to_ALU = 5'd8; //SLL/SLLI logical leftshift 
            5'b00010: Instruction_to_ALU = 5'd9; //SLT/SLTI set less than
            5'b00011: Instruction_to_ALU = 5'd10; //SLTU set less than unsigned
            5'b00100: Instruction_to_ALU = 5'd11; //XOR/XORI xor 
            5'b00101: Instruction_to_ALU = 5'd12; //SRL/SRLI logical rightshift 
            5'b01101: Instruction_to_ALU = 5'd13; //SRA/SRAI arithmetic rightshift 
            5'b00110: Instruction_to_ALU = 5'd14; //OR/ORI or
            5'b00111: Instruction_to_ALU = 5'd15; //AND/ANDI and

            default: Instruction_to_ALU = 5'd16; //throw error flag
        endcase
    end

//PIPELINING OVERRIDE DETECT

reg [4:0] previous_rd;
initial begin
    previous_rd <= 5'bzzzzz; //no previous register
end

always@(negedge IDU_ready) begin //capture address on decode
    previous_rd <= rd;
end

always@(posedge IDU_ready) begin
    if(previous_rd == rs1) begin//OVERRIDE CASES
        pipelining_override <= 2'b01;
    end
    if(previous_rd == rs2) begin
        pipelining_override <= 2'b10;
    end
    else begin
        pipelining_override <= 2'b00;
    end
end

a

    
    always@(negedge Fetch_ready or reset) begin
        //reset everything no error flag
        
    end

endmodule