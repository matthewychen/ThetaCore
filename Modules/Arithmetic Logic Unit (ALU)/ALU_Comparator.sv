module Comparator(
    //templated
    input soc_clk,
    input reset,
    input dat_ready,
    input [31:0] ALU_dat1,
    input [31:0] ALU_dat2,
    input [3:0] decryptedOP,
    
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
    else 
    if (decryptedOP == 0) begin //BEQ
        if(ALU_dat1 == ALU_dat2) begin
            Comparator_con_met <= 1'b1;
        end
        else begin
            Comparator_con_met <= 1'b0;
        end
    end
    if (decryptedOP == 1) begin //BNE
        if(ALU_dat1 != ALU_dat2) begin
            Comparator_con_met <= 1'b1;
        end
        else begin
            Comparator_con_met <= 1'b0;
        end
    end
    if (decryptedOP == 2) begin //BLT
        if($signed(ALU_dat1) < $signed(ALU_dat2)) begin
            Comparator_con_met <= 1'b1;
        end
        else begin
            Comparator_con_met <= 1'b0;
        end
    end
    if (decryptedOP == 3) begin //BGE
        if($signed(ALU_dat1) >= $signed(ALU_dat2)) begin
            Comparator_con_met <= 1'b1;
        end
        else begin
            Comparator_con_met <= 1'b0;
        end
    end
    if (decryptedOP == 4) begin //BLTU
        if(ALU_dat1 < ALU_dat2) begin
            Comparator_con_met <= 1'b1;
        end
        else begin
            Comparator_con_met <= 1'b0;
        end
    end
    if (decryptedOP == 5) begin //BGEU
        if(ALU_dat1 >= ALU_dat2) begin
            Comparator_con_met <= 1'b1;
        end
        else begin
            Comparator_con_met <= 1'b0;
        end
    end
    if (decryptedOP == 9) begin //SLT/SLTI
        if($signed(ALU_dat1) < $signed(ALU_dat2)) begin
            Comparator_con_met <= 1'b1;
        end
        else begin
            Comparator_con_met <= 1'b0;
        end
    end
    if (decryptedOP == 10) begin //SLTU/SLTIU
        if(ALU_dat1 < ALU_dat2) begin
            Comparator_con_met <= 1'b1;
        end
        else begin
            Comparator_con_met <= 1'b0;
        end
    end
end


endmodule