module Shifter(
    input [31:0] ALU_dat1,
    input [31:0] ALU_dat2,
    input [4:0]  Instruction_to_ALU,

    output reg [31:0] Shifter_out
);

always @(*) begin
    // default
    Shifter_out = 32'b0;

    case (Instruction_to_ALU)
        5'd8:  Shifter_out = ALU_dat1 <<  ALU_dat2[4:0];               // SLL
        5'd12: Shifter_out = ALU_dat1 >>  ALU_dat2[4:0];               // SRL
        5'd13: Shifter_out = $signed(ALU_dat1) >>> ALU_dat2[4:0];      // SRA
        default: Shifter_out = 32'b0;
    endcase
end

endmodule
