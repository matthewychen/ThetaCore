module IDU_top(
    //templated
    input soc_clk,
    input IDU_reset, //flushing
    input [31:0] instruction,
    input Fetch_ready,
    input IDU_stall,
    input IDU_poweron,

    output reg IDU_ready, //CU read cue
    output reg [4:0] Instruction_to_ALU, //ALU instruction select, only driven if relevant, otherwise left at invalid = 5'd16
    //output [3:0] ALU_module_select, //one-hot
        //4'b0001 -> Addsub
        //4'b0010 -> Comparator
        //4'b0100 -> Logop
        //4'b1000 -> Shifter
        //4'b0000 -> null/no activation
    output reg [5:0] Instruction_to_CU, //CU instruction select, superset of ALU_module. refer to cu_code_ref.md to decode.

    //databusses
    output reg [31:0] imm,
    output reg [4:0] rd, //CU register sel
    output reg [4:0] rs1,
    output reg [4:0] rs2,
    output reg [4:0] shamt,
    output reg [31:0] pc_increment,

    //flags
    output reg [1:0] pipeline_override,
    //00 -> no override
    //01 -> override rs1
    //10 -> override rs2
    output reg invalid_instruction
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
//9  -> fence/fence.i
//10  -> ecall/ebreak
//11 -> invalid
//12 -> initial

always@(posedge IDU_poweron) begin
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
    //IDU_result_counter <= 0;
    //set all output regs to default/deasserted state
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

        7'b0001111: decryptedOPtype = 9; //fence
        7'b1110011: decryptedOPtype = 10; //ecall/ebreak
        
        default: decryptedOPtype = 11; //error case
    endcase
end

always@(decryptedOPtype) begin
    case(decryptedOPtype)
        4'd0: begin //LUI U
            imm = {reg_instruction[31:12], {12{1'b0}}};
            rd = reg_instruction[11:7];
            rs1 = 5'bz;
            rs2 = 5'bz;
            shamt = 5'bz;
            pc_increment = 4;
            Instruction_to_CU = 0;
            invalid_instruction = 0;
        end
        4'd1: begin//AUIPC U
            imm = {reg_instruction[31:12], {12{1'b0}}};
            rd = reg_instruction[11:7];
            rs1 = 5'bz;
            rs2 = 5'bz;
            shamt = 5'bz;
            pc_increment = 4;
            Instruction_to_CU = 1;
            invalid_instruction = 0;
        end
        4'd2: begin//JAL J
            imm = 32'b0;
            rd = reg_instruction[11:7];
            rs1 = 5'bz;
            rs2 = 5'bz;
            shamt = 5'bz;
            pc_increment = {{11{reg_instruction[31]}}, reg_instruction[31], reg_instruction[19:12], reg_instruction[20], reg_instruction[30:21],1'b0}; //note the ending with 1'b0 as jumps must be aligned to the nearest 2 bytes to accommodate for R16 instructions.
            Instruction_to_CU = 2;
            invalid_instruction = 0;
        end
        4'd3: begin//JALR J
            imm = {{20{reg_instruction[31]}}, reg_instruction[31:20]}; //same logic as above, but note that the lsb does not need to be 0 as rs1 + imm can both be odd and result in an even address. if it doesn't, make sure to cut off the last bit.
            rd = reg_instruction[11:7];
            rs1 = reg_instruction[19:15];
            rs2 = 5'bz;
            shamt = 5'bz;
            pc_increment = 4;
            Instruction_to_CU = 3;
            invalid_instruction = 0;
        end
        4'd4: begin//B
            imm = {{19{reg_instruction[31]}}, reg_instruction[31], reg_instruction[7], reg_instruction[30:25], reg_instruction[11:8], 1'b0};
            rd = 5'bz;
            rs1 = reg_instruction[19:15];
            rs2 = reg_instruction[24:20];
            shamt = 5'bz;
            pc_increment = 4;
            invalid_instruction = 0;
            case(reg_instruction[14:12])
                3'b000: Instruction_to_CU = 4; //beq
                3'b001: Instruction_to_CU = 5; //bne
                3'b100: Instruction_to_CU = 6; //blt
                3'b101: Instruction_to_CU = 7; //bge
                3'b110: Instruction_to_CU = 8; //bltu
                3'b111: Instruction_to_CU = 9; //bgeu
                default: invalid_instruction = 1;
            endcase
        end
        4'd5: begin//S
            imm = {{20{reg_instruction[31]}}, reg_instruction[31], reg_instruction[30:25], reg_instruction[11:7]};
            rd = 5'bz;
            rs1 = reg_instruction[19:15];
            rs2 = reg_instruction[24:20];
            shamt = 5'bz;
            pc_increment = 4;
            invalid_instruction = 0;
            case(reg_instruction[14:12])
                3'b000: Instruction_to_CU = 10; //sb
                3'b001: Instruction_to_CU = 11; //sh
                3'b010: Instruction_to_CU = 12; //sw
                default: invalid_instruction = 1;
            endcase
        end
        4'd6: begin//IG1 I (load)
            imm = {{20{reg_instruction[31]}}, reg_instruction[31:20]};
            rd = reg_instruction[11:7];
            rs1 = reg_instruction[19:15];
            rs2 = 5'bz;
            shamt = 5'bz;
            pc_increment = 4;
            invalid_instruction = 0;
            case(reg_instruction[14:12])
                3'b000: Instruction_to_CU = 13; //lb
                3'b001: Instruction_to_CU = 14; //lh
                3'b010: Instruction_to_CU = 15; //lw
                3'b100: Instruction_to_CU = 16; //lbu
                3'b101: Instruction_to_CU = 17; //lhu
                default: invalid_instruction = 1;
            endcase
        end
        4'd7: begin//IG2 I (calc)
            rd = reg_instruction[11:7];
            rs1 = reg_instruction[19:15];
            rs2 = 5'bz;
            pc_increment = 4;
            invalid_instruction = 0;
            case(reg_instruction[14:12])
                3'b000: begin //addi
                    Instruction_to_CU = 18; 
                    imm = {{20{reg_instruction[31]}}, reg_instruction[31:20]};
                    shamt = 5'bz;
                end
                3'b010: begin //slti
                    Instruction_to_CU = 19; 
                    imm = {{20{reg_instruction[31]}}, reg_instruction[31:20]};
                    shamt = 5'bz;
                end
                3'b011: begin //sltiu
                    Instruction_to_CU = 20; 
                    imm = {{20{reg_instruction[31]}}, reg_instruction[31:20]};
                    shamt = 5'bz;
                end
                3'b100: begin //xori
                    Instruction_to_CU = 21;
                    imm = {{20{reg_instruction[31]}}, reg_instruction[31:20]};
                    shamt = 5'bz;
                end
                3'b110: begin //ori
                    Instruction_to_CU = 22;
                    imm = {{20{reg_instruction[31]}}, reg_instruction[31:20]};
                    shamt = 5'bz;
                end
                3'b111: begin //andi
                    Instruction_to_CU = 23;
                    imm = {{20{reg_instruction[31]}}, reg_instruction[31:20]};
                    shamt = 5'bz;
                end


                3'b001: begin
                    Instruction_to_CU = 24;
                    imm = 32'bz;
                    shamt = reg_instruction[24:20];
                end

                3'b101: begin
                    if(!reg_instruction[30]) begin
                        Instruction_to_CU = 25;
                        imm = 32'bz;
                        shamt = reg_instruction[24:20];
                    end else begin
                        Instruction_to_CU = 26;
                        imm = 32'bz;
                        shamt = reg_instruction[24:20];
                    end
                end

                default: invalid_instruction = 1;
            endcase
        end

        4'd8: begin//R
            imm = 32'bz;
            rd = reg_instruction[11:7];
            rs1 = reg_instruction[19:15];
            rs2 = reg_instruction[24:20];
            shamt = 5'bz;
            pc_increment = 4;
            invalid_instruction = 0;
            case(reg_instruction[14:12])
                3'b000: begin
                    if(!reg_instruction[30]) begin //add
                        Instruction_to_CU = 27;
                    end else begin //sub
                        Instruction_to_CU = 28;
                    end
                end
                3'b001: Instruction_to_CU = 29; //sll
                3'b010: Instruction_to_CU = 30; //slt
                3'b011: Instruction_to_CU = 31; //sltu
                3'b100: Instruction_to_CU = 32; //xor
                3'b101: begin 
                    if(!reg_instruction[30]) begin //srl
                        Instruction_to_CU = 33;
                    end else begin //sra
                        Instruction_to_CU = 34;
                    end
                end
                3'b110: Instruction_to_CU = 35; //or
                3'b111: Instruction_to_CU = 36; //and
                default: invalid_instruction = 1;
            endcase
        end
        4'd9: begin//FENCE/FENCE.I
            imm = 32'bz;
            rd = 5'bz;
            rs1 = 5'bz;
            rs2 = 5'bz;
            shamt = 5'bz;
            pc_increment = 4;
            invalid_instruction = 0;
            case(reg_instruction[14:12])
                3'b000: Instruction_to_CU = 37; //fence
                3'b001: Instruction_to_CU = 38; //fence.i
                default: invalid_instruction = 1;
            endcase
        end
        4'd10: begin//ECALL/EBREAK
            case(reg_instruction[20])
                1'b0 begin
                    Instruction_to_CU = 39; //ecall
                    decryptedOPtype = 12;
                    imm = 32'bz;
                    rd = 5'bz;
                    rs1 = 5'bz;
                    rs2 = 5'bz;
                    shamt = 5'bz;
                    pc_increment = 4;

                    IDU_ready = 0;
                    Instruction_to_ALU = 16;
                    //ALU_module_select <= 0;
                    Instruction_to_CU = 0;

                    invalid_instruction = 0;
                    pipeline_override = 0;

                    reg_instruction = 0;
                    IDU_result_counter = 0;
                end
                1'b1: Instruction_to_CU = 40; //ebreak means no reset
            endcase
        end

        4'd12: begin//INITIALIZED
            imm = 32'bz;
            rd = 5'bz;
            rs1 = 5'bz;
            rs2 = 5'bz;
            shamt = 5'bz;
            pc_increment = 4;
            invalid_instruction = 0;
        end

        default: begin //ERROR. should catch 11 case
            $finish;
        end
    endcase
end

    //specific instructions for ALU
    always@(Instruction_to_CU) begin 
        case(Instruction_to_CU)
            //B
            4: Instruction_to_ALU = 5'd0; //BEQ branch equal
            5: Instruction_to_ALU = 5'd1; //BNE branch not equal
            6: Instruction_to_ALU = 5'd2; //BLT branch less than
            7: Instruction_to_ALU = 5'd3; //BGE branch greater than or equal
            8: Instruction_to_ALU = 5'd4; //BLTU branch less than unsigned
            9: Instruction_to_ALU = 5'd5; //BGEU branch greater than or equal unsigned

            //I/R
            27: Instruction_to_ALU = 5'd6; //ADD add 
            18: Instruction_to_ALU = 5'd6; //ADDI add 
            28: Instruction_to_ALU = 5'd7; //SUB subtract 
            29: Instruction_to_ALU = 5'd8; //SLL logical leftshift 
            24: Instruction_to_ALU = 5'd8; //SLLI logical leftshift
            30: Instruction_to_ALU = 5'd9; //SLT set less than
            19: Instruction_to_ALU = 5'd9; //SLTI set less than
            31: Instruction_to_ALU = 5'd10; //SLTU set less than unsigned
            32: Instruction_to_ALU = 5'd11; //XOR xor 
            21: Instruction_to_ALU = 5'd11; //XORI xor 
            33: Instruction_to_ALU = 5'd12; //SRL logical rightshift 
            25: Instruction_to_ALU = 5'd12; //SRLI logical rightshift 
            34: Instruction_to_ALU = 5'd13; //SRA arithmetic rightshift
            26: Instruction_to_ALU = 5'd13; //SRAI arithmetic rightshift 
            35: Instruction_to_ALU = 5'd14; //OR or
            22: Instruction_to_ALU = 5'd14; //ORI or
            36: Instruction_to_ALU = 5'd15; //AND and
            23: Instruction_to_ALU = 5'd15; //ANDI and

            default: Instruction_to_ALU = 5'd16; //no operation
        endcase
        IDU_ready = 1;
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
        pipeline_override <= 2'b01;
    end
    else if(previous_rd == rs2) begin
        pipeline_override <= 2'b10;
    end
    else begin
        pipeline_override <= 2'b00;
    end
end
    
//use IDU result counter to push IDU_ready flag.
//always@(posedge soc_clk) begin //buffered delay to allow for pipelining
//    if(Fetch_ready) begin
//        if(IDU_result_counter==3) begin
//            IDU_ready <= 1;
//            IDU_result_counter <= 0;
//        end
//        else begin
//            IDU_result_counter <= IDU_result_counter + 1;
//        end
//    end
//    else begin
//        IDU_ready <= 0;
//    end
//end

always@(posedge IDU_reset) begin 
    //reset everything. used for flushing
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

    IDU_ready <= 0;
end

endmodule