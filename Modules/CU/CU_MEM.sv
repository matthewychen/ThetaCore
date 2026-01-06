module CU_MEM(
    //copied from IF
    input soc_clk,
    
    input memfetch_start, //why is this here
    input [6:0] addr,
    input [3:0] bits_to_access,
    input read_or_write, //should always be read in IF
    //need to retrieve from and write data to SRAM.
    
    output [31:0] MEM_data //instruction to CU
);

    //reset and stall capture

    always @(posedge soc_clk) begin //unconditional stage incrementation
        MEM_stage_counter <= MEM_stage_counter + 1'b1;
    end


    always @(posedge soc_clk or posedge MEM_reset_reg) begin
        if (MEM_reset_reg) begin
            // Reset state
        end else begin
            case(MEM_stage_counter)
                2'b00: begin // Stage 0: Save incoming values
                end
                
                2'b01: begin // Stage 1: Maybe override inputs
                end
                
                2'b10: begin // Stage 2: Processing time
                end
                
                2'b11: begin // Stage 3: Finished
                end
            endcase
        end
    end

// need to edit and pass signals back upwards to interface with MMU

endmodule