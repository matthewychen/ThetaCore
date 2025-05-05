module CU_IF(
    //templated
    input soc_clk,
    input IF_reset,
    input IF_stall,
    input memfetch_start,
    input [31:0] addr,
    input [3:0] bits_to_access,
    input read_or_write, //should always be read in IF
    //need to retrieve from and write data to SRAM.

    output [31:0] IF_data //instruction to CU
);

    //reset and stall capture
    reg IF_reset_reg;
    reg IF_stall_reg;

    always@(posedge soc_clk or posedge IF_reset) begin
        if(IF_reset) begin
            // Immediate reset response
            IF_reset_reg <= 1;
        end else if(IF_stall) begin
            // Set stall flag
            IF_stall_reg <= 1;
        end else if(IF_stage_counter == 2'b00) begin
            // Clear flags only at stage 0 and if no new reset/stall
            IF_reset_reg <= 0;
            IF_stall_reg <= 0;
        end
    end

// need to edit and pass signals back upwards to interface with MMU


endmodule