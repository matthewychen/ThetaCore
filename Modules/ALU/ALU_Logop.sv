module LogOp(
    input soc_clk,
    input reset,
    input dat_ready,
    input [31:0] ALU_dat1,
    input [31:0] ALU_dat2,
    input [4:0] Instruction_to_ALU,

    output reg [31:0] LogOp_out
    //no flags
);

always@(posedge soc_clk) begin
    if (reset || ~dat_ready) begin
        LogOp_out <= 32'b0;
    end
    else begin
        if (Instruction_to_ALU == 15) begin //AND
            LogOp_out <= ALU_dat1 & ALU_dat2;
        end
        else if (Instruction_to_ALU == 14) begin //OR
            LogOp_out <= ALU_dat1 | ALU_dat2;

        end
        else if (Instruction_to_ALU == 11) begin //XOR
            LogOp_out <= ALU_dat1 ^ ALU_dat2;

        end
        else begin //invalid
            LogOp_out <= 32'b0;
        end
    end
end


//always@(posedge soc_clk) begin
//    if (reset || ~dat_ready) begin
//        LogOp_out <= 32'b0;
//    end
//    else begin
//        if (Instruction_to_ALU == 15) begin //AND
//            LogOp_out <= {{ALU_dat1[0] & ALU_dat2[0]}
//                          {ALU_dat1[1] & ALU_dat2[1]}
//                          {ALU_dat1[2] & ALU_dat2[2]}
//                          {ALU_dat1[3] & ALU_dat2[3]}
//                          {ALU_dat1[4] & ALU_dat2[4]}
//                          {ALU_dat1[5] & ALU_dat2[5]}
//                          {ALU_dat1[6] & ALU_dat2[6]}
//                          {ALU_dat1[7] & ALU_dat2[7]}
//                          {ALU_dat1[8] & ALU_dat2[8]}
//                          {ALU_dat1[9] & ALU_dat2[9]}
//                          {ALU_dat1[10] & ALU_dat2[10]}
//                          {ALU_dat1[11] & ALU_dat2[11]}
//                          {ALU_dat1[12] & ALU_dat2[12]}
//                          {ALU_dat1[13] & ALU_dat2[13]}
//                          {ALU_dat1[14] & ALU_dat2[14]}
//                          {ALU_dat1[15] & ALU_dat2[15]}
//                          {ALU_dat1[16] & ALU_dat2[16]}
//                          {ALU_dat1[17] & ALU_dat2[17]}
//                          {ALU_dat1[18] & ALU_dat2[18]}
//                          {ALU_dat1[19] & ALU_dat2[19]}
//                          {ALU_dat1[20] & ALU_dat2[20]}
//                          {ALU_dat1[21] & ALU_dat2[21]}
//                          {ALU_dat1[22] & ALU_dat2[22]}
//                          {ALU_dat1[23] & ALU_dat2[23]}
//                          {ALU_dat1[24] & ALU_dat2[24]}
//                          {ALU_dat1[25] & ALU_dat2[25]}
//                          {ALU_dat1[26] & ALU_dat2[26]}
//                          {ALU_dat1[27] & ALU_dat2[27]}
//                          {ALU_dat1[28] & ALU_dat2[28]}
//                          {ALU_dat1[29] & ALU_dat2[29]}
//                          {ALU_dat1[30] & ALU_dat2[30]}
//                          {ALU_dat1[31] & ALU_dat2[31]}};
//
//        end
//        else if (Instruction_to_ALU == 14) begin //OR
//            LogOp_out <= {{ALU_dat1[0] | ALU_dat2[0]}
//                          {ALU_dat1[1] | ALU_dat2[1]}
//                          {ALU_dat1[2] | ALU_dat2[2]}
//                          {ALU_dat1[3] | ALU_dat2[3]}
//                          {ALU_dat1[4] | ALU_dat2[4]}
//                          {ALU_dat1[5] | ALU_dat2[5]}
//                          {ALU_dat1[6] | ALU_dat2[6]}
//                          {ALU_dat1[7] | ALU_dat2[7]}
//                          {ALU_dat1[8] | ALU_dat2[8]}
//                          {ALU_dat1[9] | ALU_dat2[9]}
//                          {ALU_dat1[10] | ALU_dat2[10]}
//                          {ALU_dat1[11] | ALU_dat2[11]}
//                          {ALU_dat1[12] | ALU_dat2[12]}
//                          {ALU_dat1[13] | ALU_dat2[13]}
//                          {ALU_dat1[14] | ALU_dat2[14]}
//                          {ALU_dat1[15] | ALU_dat2[15]}
//                          {ALU_dat1[16] | ALU_dat2[16]}
//                          {ALU_dat1[17] | ALU_dat2[17]}
//                          {ALU_dat1[18] | ALU_dat2[18]}
//                          {ALU_dat1[19] | ALU_dat2[19]}
//                          {ALU_dat1[20] | ALU_dat2[20]}
//                          {ALU_dat1[21] | ALU_dat2[21]}
//                          {ALU_dat1[22] | ALU_dat2[22]}
//                          {ALU_dat1[23] | ALU_dat2[23]}
//                          {ALU_dat1[24] | ALU_dat2[24]}
//                          {ALU_dat1[25] | ALU_dat2[25]}
//                          {ALU_dat1[26] | ALU_dat2[26]}
//                          {ALU_dat1[27] | ALU_dat2[27]}
//                          {ALU_dat1[28] | ALU_dat2[28]}
//                          {ALU_dat1[29] | ALU_dat2[29]}
//                          {ALU_dat1[30] | ALU_dat2[30]}
//                          {ALU_dat1[31] | ALU_dat2[31]}};
//
//        end
//        else if (Instruction_to_ALU == 11) begin //XOR
//            LogOp_out <= {{ALU_dat1[0] ^ ALU_dat2[0]}
//                          {ALU_dat1[1] ^ ALU_dat2[1]}
//                          {ALU_dat1[2] ^ ALU_dat2[2]}
//                          {ALU_dat1[3] ^ ALU_dat2[3]}
//                          {ALU_dat1[4] ^ ALU_dat2[4]}
//                          {ALU_dat1[5] ^ ALU_dat2[5]}
//                          {ALU_dat1[6] ^ ALU_dat2[6]}
//                          {ALU_dat1[7] ^ ALU_dat2[7]}
//                          {ALU_dat1[8] ^ ALU_dat2[8]}
//                          {ALU_dat1[9] ^ ALU_dat2[9]}
//                          {ALU_dat1[10] ^ ALU_dat2[10]}
//                          {ALU_dat1[11] ^ ALU_dat2[11]}
//                          {ALU_dat1[12] ^ ALU_dat2[12]}
//                          {ALU_dat1[13] ^ ALU_dat2[13]}
//                          {ALU_dat1[14] ^ ALU_dat2[14]}
//                          {ALU_dat1[15] ^ ALU_dat2[15]}
//                          {ALU_dat1[16] ^ ALU_dat2[16]}
//                          {ALU_dat1[17] ^ ALU_dat2[17]}
//                          {ALU_dat1[18] ^ ALU_dat2[18]}
//                          {ALU_dat1[19] ^ ALU_dat2[19]}
//                          {ALU_dat1[20] ^ ALU_dat2[20]}
//                          {ALU_dat1[21] ^ ALU_dat2[21]}
//                          {ALU_dat1[22] ^ ALU_dat2[22]}
//                          {ALU_dat1[23] ^ ALU_dat2[23]}
//                          {ALU_dat1[24] ^ ALU_dat2[24]}
//                          {ALU_dat1[25] ^ ALU_dat2[25]}
//                          {ALU_dat1[26] ^ ALU_dat2[26]}
//                          {ALU_dat1[27] ^ ALU_dat2[27]}
//                          {ALU_dat1[28] ^ ALU_dat2[28]}
//                          {ALU_dat1[29] ^ ALU_dat2[29]}
//                          {ALU_dat1[30] ^ ALU_dat2[30]}
//                          {ALU_dat1[31] ^ ALU_dat2[31]}};
//
//        end
//        else begin //invalid
//            LogOp_out <= 32'b0;
//        end
//    end
//end

endmodule