module IDU_top(
    //templated
    input soc_clk,
    input reset,
    input [31:0] instruction,
    input Fetch_ready,

    output IDU_ready, //CU read cue
    output [4:0] Instruction_to_ALU, //ALU instruction select, only driven if relevant, otherwise left at invalid = 5'd16
    //output [3:0] ALU_module_select, //one-hot
        //4'b0001 -> Addsub
        //4'b0010 -> Comparator
        //4'b0100 -> Logop
        //4'b1000 -> Shifter
        //4'b0000 -> null/no activation
    output [5:0] Instruction_to_CU, //CU instruction select, superset of ALU_module. refer to cu_code_ref.md to decode.
    

    //databusses
    output reg [31:0] imm,
    output reg [4:0] rd, //CU register sel
    output reg [4:0] rs1,
    output reg [4:0] rs2,
    output reg [4:0] shamt,
    output reg [31:0] pc_increment,

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

    reg [1:0] IDU_result_counter;

    initial begin
        decryptedOPtype <= 12;
        imm <= 32'bz;
        rd <= 5'bz;
        rs1 <= 5'bz;
        rs2 <= 5'bz;
        shamt <= 5'bz;

        pc_increment <= 4;

        IDU_ready <= 0;
        Instruction_to_ALU <= 16;
        //ALU_module_select <= 0;
        Instruction_to_CU <= 0;

        invalid_instruction <= 0;
        pipeline_override <= 0;

        reg_instruction <= 0;
        IDU_result_counter <= 0;
        //set all output regs to default/deasserted state
    end

    //save instruction in register
    reg [31:0] reg_instruction;
    always@posedge(Fetch_ready) begin
        reg_instruction <= instruction;
    end

    always@(reg_instruction) begin //update optype
        casez(reg_instruction[6:0])
            7'b0110111: decryptedOPtype = 0;
            7'b0010111: decryptedOPtype = 1;

            7'b1101111: decryptedOPtype = 2;
            7'b1100111: decryptedOPtype = 3;

            7'b1100011: decryptedOPtype = 4;
            7'b0100011: decryptedOPtype = 5;

            7'b0000011: decryptedOPtype = 6;
            7'b0010011: decryptedOPtype = 7;
            7'b0110011: decryptedOPtype = 8;

            7'b1110011: decryptedOPtype = 9; //fence
            7'b1110011: decryptedOPtype = 10; //ecall/ebreak
            
            default: decryptedOPtype = 11; //error case
        endcase
    end

    always@(decryptedOPtype or posedge reset) begin
        if(reset==1) begin
            //reset here
        end
        else begin
            case(decryptedOPtype)
                4'd0: begin //LUI U
                    imm <= {reg_instruction[31:12], 12{1'b0}};
                    rd <= reg_instruction[11:7];
                    rs1 <= 5'bz;
                    rs2 <= 5'bz;
                    shamt <= 5'bz;
                    pc_increment <= 4;
                    Instruction_to_CU <= 0;
                    invalid_instruction <= 0;
                end
                4'd1: begin//AUIPC U
                    imm <= {reg_instruction[31:12], 12{1'b0}};
                    rd <= reg_instruction[11:7];
                    rs1 <= 5'bz;
                    rs2 <= 5'bz;
                    shamt <= 5'bz;
                    pc_increment <= 4;
                    Instruction_to_CU <= 1;
                    invalid_instruction <= 0;
                end
                4'd2: begin//JAL J
                    imm <= 32'b0;
                    rd <= reg_instruction[11:7];
                    rs1 <= 5'bz;
                    rs2 <= 5'bz;
                    shamt <= 5'bz;
                    pc_increment <= {11{reg_instruction[31]}, reg_instruction[31], reg_instruction[19:12], reg_instruction[20], reg_instruction[30:21],1'b0}; //note the ending with 1'b0 as jumps must be aligned to the nearest 2 bytes to accommodate for R16 instructions.
                    Instruction_to_CU <= 2;
                    invalid_instruction <= 0;
                end
                4'd3: begin//JALR J
                    imm <= {20{reg_instruction[31]}, reg_instruction{31:20}}; //same logic as above, but note that the lsb does not need to be 0 as rs1 + imm can both be odd and result in an even address. if it doesn't, make sure to cut off the last bit.
                    rd <= reg_instruction[11:7];
                    rs1 <= reg_instruction[19:15];
                    rs2 <= 5'bz;
                    shamt <= 5'bz;
                    pc_increment <= 4;
                    Instruction_to_CU <= 3;
                    invalid_instruction <= 0;
                end
                4'd4: begin//B
                    imm <= {19{reg_instruction[31]}, reg_instruction[31], reg_instruction[7], reg_instruction[30:25], reg_instruction[11:8], 1'b0};
                    rd <= 5'bz;
                    rs1 <= reg_instruction[19:15];
                    rs2 <= reg_instruction[24:20];
                    shamt <= 5'bz;
                    pc_increment <= 4;
                    invalid_instruction <= 0;
                    case(reg_instruction[14:12])
                        3'b000: Instruction_to_CU <= 4; //beq
                        3'b001: Instruction_to_CU <= 5; //bne
                        3'b100: Instruction_to_CU <= 6; //blt
                        3'b101: Instruction_to_CU <= 7; //bge
                        3'b110: Instruction_to_CU <= 8; //bltu
                        3'b111: Instruction_to_CU <= 9; //bgeu
                        default: invalid_instruction <= 1;
                    endcase
                end
                4'd5: begin//S
                    imm <= {20{reg_instruction[31]}, reg_instruction[31], reg_instruction[30:25], reg_instruction[11:7]};
                    rd <= 5'bz;
                    rs1 <= reg_instruction[19:15];
                    rs2 <= reg_instruction[24:20];
                    shamt <= 5'bz;
                    pc_increment <= 4;
                    invalid_instruction <= 0;
                    case(reg_instruction[14:12])
                        3'b000: Instruction_to_CU <= 10; //sb
                        3'b001: Instruction_to_CU <= 11; //sh
                        3'b010: Instruction_to_CU <= 12; //sw
                        default: invalid_instruction <= 1;
                    endcase
                end
                4'd6: begin//IG1 I
                end
                4'd7: begin//IG2 I
                end
                4'd8: begin//R
                end
                4'd9: begin//FENCE/FENCE.I
                end
                4'd10: begin//ECALL/EBREAK
                end
                4'd12: begin//INITIALIZED
                end
                default: begin //ERROR. should catch 11 case
                    $finish;
                end
            endcase
        end
    end

        //specific instructions for ALU
        always@(posedge IDU_ready) begin 
            casez(Instruction_to_CU)

                //B
                : Instruction_to_ALU = 5'd0; //BEQ branch equal
                : Instruction_to_ALU = 5'd1; //BNE branch not equal
                : Instruction_to_ALU = 5'd2; //BLT branch less than
                : Instruction_to_ALU = 5'd3; //BGE branch greater than or equal
                : Instruction_to_ALU = 5'd4; //BLTU branch less than unsigned
                : Instruction_to_ALU = 5'd5; //BGEU branch greater than or equal unsigned
                //I/R
                : Instruction_to_ALU = 5'd6; //ADD/ADDI add 
                : Instruction_to_ALU = 5'd7; //SUB subtract 
                : Instruction_to_ALU = 5'd8; //SLL/SLLI logical leftshift 
                : Instruction_to_ALU = 5'd9; //SLT/SLTI set less than
                : Instruction_to_ALU = 5'd10; //SLTU set less than unsigned
                : Instruction_to_ALU = 5'd11; //XOR/XORI xor 
                : Instruction_to_ALU = 5'd12; //SRL/SRLI logical rightshift 
                : Instruction_to_ALU = 5'd13; //SRA/SRAI arithmetic rightshift 
                : Instruction_to_ALU = 5'd14; //OR/ORI or
                : Instruction_to_ALU = 5'd15; //AND/ANDI and

                default: Instruction_to_ALU = 5'd16; //no operation
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
    

//use IDU result counter to push IDU_ready flag.

    always@(negedge Fetch_ready or reset) begin
        //reset everything no error flag
        
    end

endmodule