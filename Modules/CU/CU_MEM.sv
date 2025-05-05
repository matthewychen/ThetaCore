module CU_MEM(
    //copied from IF
    input soc_clk,
    input MEM_reset,
    input MEM_stall,
    input memfetch_start,
    input [31:0] addr,
    input [3:0] bits_to_access,
    input read_or_write, //should always be read in IF
    //need to retrieve from and write data to SRAM.
    
    output [31:0] MEM_data //instruction to CU
);

    //reset and stall capture
    reg MEM_reset_reg;
    reg MEM_stall_reg;

    always@(posedge soc_clk or posedge MEM_reset) begin
        if(MEM_reset) begin
            // Immediate reset response
            MEM_reset_reg <= 1;
        end else if(MEM_stall) begin
            // Set stall flag
            MEM_stall_reg <= 1;
        end else if(MEM_stage_counter == 2'b00) begin
            // Clear flags only at stage 0 and if no new reset/stall
            MEM_reset_reg <= 0;
            MEM_stall_reg <= 0;
        end
    end
// need to edit and pass signals back upwards to interface with MMU

endmodule