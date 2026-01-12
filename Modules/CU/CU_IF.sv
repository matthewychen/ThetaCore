module CU_IF(
    //templated
    input soc_clk,
    input IF_reset,
    input [1:0] stage_counter,
    input memfetch_start, //is this still needed if poweron?
    input [31:0] addr,
    input [3:0] bits_to_access,
    input read_or_write, //should always be read in IF
    //need to retrieve from and write data to SRAM.
    output [31:0] IF_data //instruction to CU
);

    always @(posedge soc_clk or posedge IF_reset_reg) begin
        if (IF_reset_reg) begin
            // Reset state
        end else begin
            case(stage_counter)
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