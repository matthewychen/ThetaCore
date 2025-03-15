`include "defines.vh"

module tb_top;
    //-------------------------------
    // Signal declarations
    //-------------------------------
    reg [6:0] addr;
    reg [3:0] mbyte;
    reg read_pulse;
    reg write_pulse;
    reg [31:0] datain;
    reg [31:0] dataout;

    // File handling and loop variables
    integer file;
    integer i;
    integer status;
    logic [31:0] temp_data;

    //-------------------------------
    // Waveform generation
    //-------------------------------
    initial begin
        $dumpfile("wave.vcd");
        $dumpvars(0, tb_top);
        $display("Compilation Success!");
    end

    //-------------------------------
    // Initialization and data loading
    //-------------------------------
    //SRAM dataload constructor and initialization with bits.bin
    initial begin
        // Initialize signals
        addr = 0;
        read_pulse = 0;
        write_pulse = 0;
        mbyte = 4'b1111;
        #1;

        // Open and load data file
        file = $fopen("bits.bin", "r");
        if (file == 0) begin
            $display("File access error.");
            $finish;
        end

        // Load data into SRAM
        for (i = 0; i < 128; i = i + 1) begin
             status = $fscanf(file, "%b\n", temp_data);
             datain = temp_data;
             $display("writing: %b, to address: %b", datain, addr);
             write_pulse = 1;
             #1;
             write_pulse = 0;
             #1;
             addr = addr + 1;
        end

        $fclose(file);
    // Demonstrate byte addressability by overwriting first 2 bytes
    #10; // Wait for previous operations to complete
    $display("Testing byte addressability - writing FFFF to first 2 bytes of each address");

    for (i = 0; i < 128; i = i + 1) begin
        addr = i;
        datain = 32'hFFFF0000; // FF in the first 2 bytes, 00 in the last 2
        mbyte = 4'b1010;       // Enable only first 2 bytes
        write_pulse = 1;
        #1;
        write_pulse = 0;
        #1;
    end

    mbyte = 4'b1111; // Restore full byte accessibility
    end

    //-------------------------------
    // Main test sequence
    //-------------------------------
    //testbench begin
    initial begin
        #7000; // Wait for initialization to complete

        //test write functionality
        addr = 7'd11;
        #1;
        write_pulse = 1;
        datain = 32'hFACEB00C;
        #1;
        write_pulse = 0;
        #1000;
        mbyte = 4'b1111;
        // Sequential read test
        addr = 0;
        for (i = 0; i < 128; i = i + 1) begin
            read_pulse = 1;
            #1;
            read_pulse =  0;
            #1;
            addr = addr + 1;
        end
        // Test reading only 2 LSB bytes
        $display("Testing partial read - reading only 2 LSB bytes");
        addr = 7'd11;
        #1;
        read_pulse = 1;
        #1;
        $display("Reading LSB bytes from addr %0d: 0x%h", addr, dataout);
        read_pulse = 0;
        $finish;
    end

    //-------------------------------
    // Module instantiation
    //-------------------------------
    //Instantiations 
    SRAM SRAM_DUT(
        .addr_sel(addr),
        .byte_sel(mbyte),
        .read_pulse(read_pulse),
        .write_pulse(write_pulse),
        .datain(datain),
        .dataout(dataout)
    );
endmodule
