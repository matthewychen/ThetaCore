`include "cu_opcodes.vh"

//==============================================================================
// Memory management unit.
//
// Owns the byte-lane work that SRAM_sim explicitly refuses to do: it supports
// partial WRITES via byte_sel, but every READ returns a whole 32-bit word.
// So lb/lh/lbu/lhu lane selection and sign-extension must happen here, and
// sb/sh must rotate their datum into the correct lane before it reaches the
// byte enables.
//
// The CU supplies width and signedness rather than raw byte enables: it is the
// thing that knows the opcode, and computing enables from an address is the
// memory's job, not the control unit's.
//==============================================================================

module MMU(
    input soc_clk,
    input reset,

    // FROM CU
    input [31:0] CU_address,    // byte address
    input [1:0]  CU_width,      // MEMW_BYTE / MEMW_HALF / MEMW_WORD
    input        CU_signed,     // 1 = sign-extend (lb/lh), 0 = zero-extend (lbu/lhu)
    input [31:0] CU_dat_in,     // store data, right-justified
    input        read_or_write, // MEMRW_READ / MEMRW_WRITE
    input        retrieve,      // start an access

    // TO CU
    output        MMU_ready,
    output [31:0] MMU_dat_out
);

    localparam M_IDLE    = 2'd0,
               M_ACCESS  = 2'd1,
               M_CAPTURE = 2'd2,
               M_DONE    = 2'd3;

    reg  [1:0]  mstate;
    reg  [31:0] addr_r;
    reg  [1:0]  width_r;
    reg         signed_r;
    reg  [31:0] wdata_r;
    reg  [3:0]  bytesel_r;
    reg         read_pulse, write_pulse;
    reg  [31:0] sram_dat_r;
    wire [31:0] sram_dataout;

    //--------------------------------------------------------------------------
    // Store path: rotate the datum into its byte lane and derive the enables.
    //--------------------------------------------------------------------------
    reg [3:0]  bytesel_c;
    reg [31:0] wdata_c;

    always @(*) begin
        case (CU_width)
            `MEMW_BYTE: begin
                bytesel_c = 4'b0001 << CU_address[1:0];
                case (CU_address[1:0])
                    2'd0: wdata_c = {24'b0, CU_dat_in[7:0]};
                    2'd1: wdata_c = {16'b0, CU_dat_in[7:0],  8'b0};
                    2'd2: wdata_c = { 8'b0, CU_dat_in[7:0], 16'b0};
                    2'd3: wdata_c = {       CU_dat_in[7:0], 24'b0};
                endcase
            end
            `MEMW_HALF: begin
                bytesel_c = CU_address[1] ? 4'b1100 : 4'b0011;
                wdata_c   = CU_address[1] ? {CU_dat_in[15:0], 16'b0}
                                          : {16'b0, CU_dat_in[15:0]};
            end
            default: begin
                bytesel_c = 4'b1111;
                wdata_c   = CU_dat_in;
            end
        endcase
    end

    //--------------------------------------------------------------------------
    // Load path: select the lane out of the returned word, then extend.
    //--------------------------------------------------------------------------
    reg [7:0]  lane_b;
    reg [15:0] lane_h;
    reg [31:0] load_c;

    always @(*) begin
        case (addr_r[1:0])
            2'd0: lane_b = sram_dat_r[7:0];
            2'd1: lane_b = sram_dat_r[15:8];
            2'd2: lane_b = sram_dat_r[23:16];
            2'd3: lane_b = sram_dat_r[31:24];
        endcase
        lane_h = addr_r[1] ? sram_dat_r[31:16] : sram_dat_r[15:0];

        case (width_r)
            `MEMW_BYTE: load_c = signed_r ? {{24{lane_b[7]}},  lane_b}
                                          : {24'b0,           lane_b};
            `MEMW_HALF: load_c = signed_r ? {{16{lane_h[15]}}, lane_h}
                                          : {16'b0,           lane_h};
            default:    load_c = sram_dat_r;
        endcase
    end

    assign MMU_dat_out = load_c;
    assign MMU_ready   = (mstate == M_DONE);

    //--------------------------------------------------------------------------
    // SRAM. Word addressed: 128 words x 4 bytes, so the index is addr[8:2].
    //--------------------------------------------------------------------------
    SRAM_sim sram_inst (
        .clk         (soc_clk),
        .reset       (reset),
        .addr_sel    (addr_r[8:2]),
        .byte_sel    (bytesel_r),
        .read_enable (read_pulse),
        .write_enable(write_pulse),
        .datain      (wdata_r),
        .dataout     (sram_dataout)
    );

    //--------------------------------------------------------------------------
    // Access sequencer.
    //--------------------------------------------------------------------------
    always @(posedge soc_clk or posedge reset) begin
        if (reset) begin
            mstate      <= M_IDLE;
            read_pulse  <= 1'b0;
            write_pulse <= 1'b0;
            addr_r      <= 32'b0;
            width_r     <= 2'b0;
            signed_r    <= 1'b0;
            wdata_r     <= 32'b0;
            bytesel_r   <= 4'b0;
            sram_dat_r  <= 32'b0;
        end else begin
            case (mstate)
                M_IDLE: if (retrieve) begin
                    // Latch every input. The MMU owns the access from here, so
                    // the CU changing its mind mid-flight cannot corrupt it.
                    addr_r      <= CU_address;
                    width_r     <= CU_width;
                    signed_r    <= CU_signed;
                    wdata_r     <= wdata_c;
                    bytesel_r   <= bytesel_c;
                    read_pulse  <= (read_or_write == `MEMRW_READ);
                    write_pulse <= (read_or_write == `MEMRW_WRITE);
                    mstate      <= M_ACCESS;
                end

                M_ACCESS: begin
                    // The SRAM commits a write on the edge entering this state,
                    // so one cycle of write_enable is enough -- holding it
                    // longer would just repeat the same store.
                    write_pulse <= 1'b0;
                    mstate      <= M_CAPTURE;
                end

                M_CAPTURE: begin
                    // read_enable had to stay asserted through this edge.
                    // SRAM_sim gates dataout behind read_enable, so dropping it
                    // in M_ACCESS would zero the bus before anyone could sample
                    // the word it had just latched.
                    sram_dat_r <= sram_dataout;
                    read_pulse <= 1'b0;
                    mstate     <= M_DONE;
                end

                M_DONE: mstate <= M_IDLE;
            endcase
        end
    end

endmodule
