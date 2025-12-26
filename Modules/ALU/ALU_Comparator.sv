module Comparator(
    input  [31:0] ALU_dat1,
    input  [31:0] ALU_dat2,
    input  [4:0]  Instruction_to_ALU,

    output reg        Comparator_con_met,
    output reg [31:0] Comparator_out
);

always @(*) begin
    // defaults (prevents latches)
    Comparator_con_met = 1'b0;
    Comparator_out     = 32'b0;

    case (Instruction_to_ALU)
        5'd0: begin // BEQ
            Comparator_con_met = (ALU_dat1 == ALU_dat2);
        end
        5'd1: begin // BNE
            Comparator_con_met = (ALU_dat1 != ALU_dat2);
        end
        5'd2: begin // BLT (signed)
            Comparator_con_met = ($signed(ALU_dat1) < $signed(ALU_dat2));
        end
        5'd3: begin // BGE (signed)
            Comparator_con_met = ($signed(ALU_dat1) >= $signed(ALU_dat2));
        end
        5'd4: begin // BLTU (unsigned)
            Comparator_con_met = (ALU_dat1 < ALU_dat2);
        end
        5'd5: begin // BGEU (unsigned)
            Comparator_con_met = (ALU_dat1 >= ALU_dat2);
        end
        5'd9: begin // SLT (signed)
            Comparator_out = ($signed(ALU_dat1) < $signed(ALU_dat2)) ? 32'd1 : 32'd0;
        end
        5'd10: begin // SLTU (unsigned)
            Comparator_out = (ALU_dat1 < ALU_dat2) ? 32'd1 : 32'd0;
        end
        default: begin
            // already zeroed
        end
    endcase
end

endmodule
