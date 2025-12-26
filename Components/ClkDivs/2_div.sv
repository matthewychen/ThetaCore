module 2_div(
    input i_clk,
    output reg o_clk
);

reg state;

initial begin
    state = 0;
    o_clk = 0;
end

always@(posedge i_clk) begin
    state <= ~state;
    if(~state) begin
        o_clk <= ~o_clk;
    end
end

endmodule
