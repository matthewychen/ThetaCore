//==============================================================================
// RV32I architectural register file.
//
// Two combinational read ports, one clocked write port. Reads are
// combinational (as in the Berkeley datapath, where Reg[] has no clock on the
// DataA/DataB path) so that operands are available to the ALU in the same
// cycle the register numbers are presented.
//==============================================================================

module regfile(
    input soc_clk,
    input reset,

    // read ports, combinational
    input  [4:0]  rs1_addr,
    input  [4:0]  rs2_addr,
    output [31:0] rs1_data,
    output [31:0] rs2_data,

    // write port, clocked
    input         RegWEn,
    input  [4:0]  rd_addr,
    input  [31:0] rd_data
);

    reg [31:0] regs [31:0];
    integer i;

    // x0 is hardwired to zero. Guarded on BOTH the read and the write path:
    // the write below refuses rd_addr == 0, and these reads return zero
    // regardless. Either guard alone is sufficient, so a mistake in one
    // cannot corrupt x0 -- which would otherwise be a spectacularly
    // confusing bug, since x0 is the source of every synthesised constant.
    assign rs1_data = (rs1_addr == 5'd0) ? 32'b0 : regs[rs1_addr];
    assign rs2_data = (rs2_addr == 5'd0) ? 32'b0 : regs[rs2_addr];

    always @(posedge soc_clk or posedge reset) begin
        if (reset) begin
            // Clearing all 32 on reset is a simulation-determinism choice, not
            // a hardware requirement: real silicon leaves them undefined. We
            // removed every X/Z source from the IDU in B3 precisely so that an
            // X appearing in a waveform means a real bug; an uninitialised
            // register file would put that back.
            for (i = 0; i < 32; i = i + 1) regs[i] <= 32'b0;
        end else if (RegWEn && rd_addr != 5'd0) begin
            regs[rd_addr] <= rd_data;
        end
    end

endmodule
