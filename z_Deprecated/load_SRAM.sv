`include "defines.vh"

module load_SRAM();
    SRAM_itf SRAM();
    integer file;
    integer i;
    integer status;
    logic [31:0] temp_data;
    
    initial begin
        file = $fopen("bits.bin", "r");
        if (file == 0) begin
            $display("File access error.");
            $finish;
        end
        SRAM.addr = 0;
        SRAM.addr_ready = 0;
        SRAM.read_pulse = 0;
        SRAM.write_pulse = 0;

        for (i = 0; i < 128; i = i + 1) begin
             status = $fscanf(file, "%b\n", temp_data);
             SRAM.datain = temp_data;
             $display("writing: %b, to address: %b", SRAM.datain, SRAM.addr);
             SRAM.write_pulse = 1;
             #1;
             SRAM.write_pulse = 0;
             #1;
             SRAM.addr = SRAM.addr + 1;
        end

        $fclose(file);
    end
endmodule