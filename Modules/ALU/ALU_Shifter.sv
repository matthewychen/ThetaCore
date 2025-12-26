module Shifter(
    input soc_clk,
    input reset,
    input dat_ready,
    input [31:0] ALU_dat1,
    input [31:0] ALU_dat2,
    input [4:0] Instruction_to_ALU,

    output reg [31:0] Shifter_out
);

always@(posedge soc_clk) begin
    if (reset) begin
        Shifter_out <= 32'b0;
    end
    else if (dat_ready) begin
        case (Instruction_to_ALU)
            5'd8: Shifter_out <= ALU_dat1 << ALU_dat2[4:0]; // SLL
            5'd12: Shifter_out <= ALU_dat1 >> ALU_dat2[4:0]; // SRL
            5'd13: Shifter_out <= $signed(ALU_dat1) >>> ALU_dat2[4:0]; // SRA
            default: Shifter_out <= 32'b0;
        endcase
    end
end


endmodule