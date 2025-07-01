module CU_MEM(
    //copied from IF
    input soc_clk,
    input MEM_reset,
    input MEM_stall,
    input MEM_poweron,
    
    input memfetch_start, //why is this here
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

always@(posedge MEM_poweron) begin //happens once on poweron
    MEM_stage_counter <= 2'b11; //let it wrap to 00 on the first posedge of soc_clk
    MEM_reset_reg <= 0;
    MEM_stall_reg <= 0;
end

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