`timescale 1ns / 1ps

module delitel#(mod = 188)(
    input clk,
    output reg out
);

wire [$clog2(mod / 2) - 1:0] out_count;

initial
    out = 0;
    schet#(.mod(mod / 2)) schet(.clk(clk), .dir(0), .out(out_count));
    always@(negedge clk)
    begin
        if(out_count == 0)
            out <= ~out;
    end
endmodule