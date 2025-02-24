`include "defines.vh"

module tb_top;

    reg [6:0] addr;
    reg addr_ready;
    reg read_pulse;
    reg write_pulse;

    reg [31:0] datain;
    reg [31:0] dataout;

    integer file;
    integer i;
    integer status;
    logic [31:0] temp_data;

    //waveform dumpblock
    initial begin
        $dumpfile("wave.vcd");
        $dumpvars(0, tb_top);
        $display("Compilation Success!");
    end

    //SRAM dataload constructor and initialization with bits.bin
    initial begin
        file = $fopen("bits.bin", "r");
        if (file == 0) begin
            $display("File access error.");
            $finish;
        end
        addr = 0;
        addr_ready = 0;
        read_pulse = 0;
        write_pulse = 0;
        #1;

        for (i = 0; i < 128; i = i + 1) begin
             status = $fscanf(file, "%b\n", temp_data);
             datain = temp_data;
             $display("writing: %b, to address: %b", datain, addr);
             addr_ready = 1;
             #1;
             write_pulse = 1;
             #1;
             write_pulse = 0;
             #1;
             addr_ready = 0;
             #1;
             addr = addr + 1;
        end

        $fclose(file);
    end

    //testbench begin
    initial begin
        #7000;
        //test write functionality
        addr = 7'd11;
        #1;
        addr_ready = 1;
        #1;
        write_pulse = 1;
        #1;
        datain = 32'b10101010101;
        #1;
        write_pulse = 0;
        addr_ready = 0;
        #1000;
        addr = 0;
        for (i = 0; i < 128; i = i + 1) begin
            #1;
            addr_ready = 1;
            #1;
            read_pulse = 1;
            #1;
            read_pulse = 0;
            #1;
            addr_ready = 0;
            #1
            addr = addr + 1;
        end
        $finish;
    end

    //Instantiations 
    SRAM SRAM_DUT(
        .addr(addr), 
        .addr_ready(addr_ready),
        .read_pulse(read_pulse),
        .write_pulse(write_pulse),
        .datain(datain),
        .dataout(dataout)
    );
endmodule
