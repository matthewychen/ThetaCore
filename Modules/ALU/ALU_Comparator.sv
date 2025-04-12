module Comparator(
    //templated
    input soc_clk,
    input reset,
    input dat_ready,
    input [31:0] ALU_dat1,
    input [31:0] ALU_dat2,
    input [4:0] Instruction_to_ALU,
    
    output reg Comparator_con_met,
    output reg [31:0] Comparator_out
);

initial begin
    Comparator_con_met = 1'b0;
    Comparator_out = 32'b0;
end

always@(posedge soc_clk) begin
    if (reset || ~dat_ready) begin
        Comparator_con_met <= 1'b0;
    end
    else if (Instruction_to_ALU == 0) begin //BEQ
        if(ALU_dat1 == ALU_dat2) begin
            Comparator_con_met <= 1'b1;
        end
        else begin
            Comparator_con_met <= 1'b0;
        end
    end
    else if (Instruction_to_ALU == 1) begin //BNE
        if(ALU_dat1 != ALU_dat2) begin
            Comparator_con_met <= 1'b1;
        end
        else begin
            Comparator_con_met <= 1'b0;
        end
    end
    else if (Instruction_to_ALU == 2) begin //BLT
        if($signed(ALU_dat1) < $signed(ALU_dat2)) begin
            Comparator_con_met <= 1'b1;
        end
        else begin
            Comparator_con_met <= 1'b0;
        end
    end
    else if (Instruction_to_ALU == 3) begin //BGE
        if($signed(ALU_dat1) >= $signed(ALU_dat2)) begin
            Comparator_con_met <= 1'b1;
        end
        else begin
            Comparator_con_met <= 1'b0;
        end
    end
    else if (Instruction_to_ALU == 4) begin //BLTU
        if(ALU_dat1 < ALU_dat2) begin
            Comparator_con_met <= 1'b1;
        end
        else begin
            Comparator_con_met <= 1'b0;
        end
    end
    else if (Instruction_to_ALU == 5) begin //BGEU
        if(ALU_dat1 >= ALU_dat2) begin
            Comparator_con_met <= 1'b1;
        end
        else begin
            Comparator_con_met <= 1'b0;
        end
    end
    else if (Instruction_to_ALU == 9) begin //SLT/SLTI
        if($signed(ALU_dat1) < $signed(ALU_dat2)) begin
            Comparator_con_met <= 1'b1;
        end
        else begin
            Comparator_con_met <= 1'b0;
        end
    end
    else if (Instruction_to_ALU == 10) begin //SLTU/SLTIU
        if(ALU_dat1 < ALU_dat2) begin
            Comparator_con_met <= 1'b1;
        end
        else begin
            Comparator_con_met <= 1'b0;
        end
    end
    else begin
        Comparator_con_met <= 1'b0;
    end
end

always@(posedge soc_clk) begin
    if (reset || ~dat_ready) begin
        Comparator_out <= 32'b0;
    end
    else begin
        case (Instruction_to_ALU)
            // For branch instructions, keep output 0 per RISC-V spec
            5'd0, 5'd1, 5'd2, 5'd3, 5'd4, 5'd5: 
                Comparator_out <= 32'b0;
            
            // For SLT/SLTU, set output to 1 or 0 based on comparison
            5'd9: Comparator_out <= ($signed(ALU_dat1) < $signed(ALU_dat2)) ? 32'd1 : 32'd0;
            5'd10: Comparator_out <= (ALU_dat1 < ALU_dat2) ? 32'd1 : 32'd0;
            
            default: Comparator_out <= 32'b0;
        endcase
    end
end

endmodule