module Shifter(
    //templated
    input soc_clk,
    input reset,
    input dat_ready,
    input [31:0] ALU_dat1,
    input [31:0] ALU_dat2, //SHAMT: use only lower 5 bits. when formatting rs2 in ALU preprocessing, make sure to use lower bits as well
    input [2:0] ALU_opcode,
    input [3:0] decryptedOP,

    output [31:0] Shifter_out
);

always@(posedge soc_clk) begin
    if (reset || ~dat_ready) begin
        Shifter_out <= 32'b0;
    end
    else begin
        if (decryptedOP == 8) begin //SLL
            Shifter_out <= ALU_dat1 << ALU_dat2[4:0];
        end

        else if (decryptedOP == 12) begin //SRL
            Shifter_out <= ALU_dat1 >> ALU_dat2[4:0];
        end

        else if (decryptedOP == 13) begin //SRA
            Shifter_out <= $signed(ALU_dat1) >>> ALU_dat2[4:0];
        end
        
        else begin
            Shifter_out <= 32'b0;
        end
    end
end

endmodule