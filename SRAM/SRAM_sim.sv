//SRAM used for simulation due to ease of not needing to debug 4000 separate modules for individual bits. Attempt to match the behavior of SRAM.

module SRAM_sim(
    input  logic        clk,
    input  logic        reset,
    input  logic [6:0]  addr_sel,
    input  logic [3:0]  byte_sel,
    input  logic        read_enable,    // synchronous read enable
    input  logic        write_enable,   // synchronous write enable
    input  logic [31:0] datain,
    output wire [31:0] dataout
);

    reg [31:0] memory [127:0];
    reg [31:0] reg_dataout;
    reg read_valid;


    integer i;

    initial begin
        for (i = 0; i < 128; i = i + 1) begin
            memory[i] = 32'b0;
        end
    end

    // Drive WL_sel and byte selection synchronously
    always @(posedge clk) begin
        if (reset) begin            
        end else begin
            if (write_enable && read_enable) begin
            end
            else if (write_enable) begin
                if(byte_sel[0]==1) begin
                    memory[addr_sel][7:0] <= datain[7:0];
                end

                if(byte_sel[1]==1) begin
                    memory[addr_sel][15:8] <= datain[15:8];
                end

                if(byte_sel[2]==1) begin
                    memory[addr_sel][23:16] <= datain[23:16];
                end
                
                if(byte_sel[3]==1) begin
                    memory[addr_sel][31:24] <= datain[31:24];
                end
            end
            else if (read_enable) begin //partial reads are not supported, only partial writes
                reg_dataout <= memory[addr_sel];
                read_valid  <= 1'b1;
            end
        end
    end
    
assign dataout = (reset || !read_valid) ? 32'b0 : reg_dataout;


endmodule
