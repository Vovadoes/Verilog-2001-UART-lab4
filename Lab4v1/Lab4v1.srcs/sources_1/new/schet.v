`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 01.11.2024 10:48:57
// Design Name: 
// Module Name: schet
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module schet#(step = 1, mod = 188)(
  input dir, clk,
  output reg [$clog2(mod)-1:0] out
);
initial
    out = 0;
always@(posedge clk)
begin
    if (dir == 0)
        out <= (out + step) % mod;
    else
        if (out < step)
            out <= (out + mod) - step;
        else
            out <= out - step;
end
endmodule
