`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 20.03.2025 09:45:26
// Design Name: 
// Module Name: automat
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


module automat_2(
    input [15:0] data_in,
    input clk,
    input reset,
    input [1:0] R_I,
    output [15:0] data_out,
    output reg [1:0] R_E,
    output reg R_O,
    output reg [6:0] state,
    output reg [15:0] x,
    output wire [15:0] sum_out, mul_out, div_out,
    output wire R_O_sum, R_O_mul, R_O_div,
    output wire [15:0] a_, b_, c_,
    output reg [15:0] a_sum, b_sum, a_mul, b_mul, a_div, b_div
    );

reg reset_sum, reset_mul, reset_div, R_I_sum, R_I_mul, R_I_div;
wire [3:0] state_sum, state_mul, state_div;
reg [15:0] a, b, c;
reg [15:0] result;
reg [15:0] x1, a11, a1, b1, fb, fb1, fx, fx1, denum, tmp, drob;
reg [15:0] num, px, dx;
reg [9:0] cnt;

initial
begin
    state <= 0;
    result <= 0;
    R_O <= 0;
    R_E <= 0;
    
    cnt <= 0;
    x <= 16'h0;
    x1 <= 16'h5640;
end

always@(posedge clk)
begin
    if (reset) begin
        state <= 0;
        x <= 0;
        a <= 0;
        b <= 0;
        c <= 0;
    end else begin
        case(state)
            0:
            begin
                a <= 0;
                b <= 0;
                c <= 0;
                result <= 0;
                R_E <= 0;
                R_O <= 0;
                cnt <= 0;
                state <= 1;
            end
    
            1:
            begin
                if (R_I == 1) begin
                    a <= data_in;
                    state <= 2;
                end else begin
                    a <= a;
                    state <= state;
                end
            end
    
            2:
            begin
                if (R_I == 2) begin
                    b <= data_in;
                    state <= 3;
                end else begin
                    b <= b;
                    state <= state;
                end
            end
            
            3: 
            begin
                if (R_I == 3) begin
                    c <= data_in;
                    //$display("%d, %d, %d", a, b, c);
                    if (a == 0) begin
                        R_E <= 2;
                        R_O <= 1;
                        state <= 0;
                    end else begin
                        MUL_in (16'h4000, a);
                        state <= 4;
                    end
                end else begin
                    c <= c;
                    state <= state;
                end
            end
            
            4:
            begin
                R_I_mul <= 0;
                if (R_O_mul) begin
                    tmp <= mul_out;
                    state <= 5;
                end else begin
                    state <= state;
                end
            end
            
            5:
            begin
                DIV_in ({~b[15], b[14:0]}, tmp);
                state <= 6;
            end
            
            6:
            begin
                R_I_div <= 0;
                if (R_O_div) begin
                    x <= div_out;
                    state <= 7;
                end else begin
                    state <= state;
                end
            end
    
            7: if (cnt < 1000) begin
                   cnt <= cnt + 1;
                   state <= 8;
               end else begin
                   R_E <= 1;
                   R_O <= 1;
                   state <= 0;
               end
    
            8:
            begin
                px <= x;
                SUM_in (x1, {~x[15], x[14:0]});
                state <= 9;
            end
    
            9: 
            begin
                R_I_sum <= 0;
                if (R_O_sum) begin
                    num <= sum_out;
                    MUL_in (x1, x1);
                    state <= 10;
                end else begin
                    state <= state;
                end
            end
            
            10: 
            begin
                R_I_mul <= 0;
                if (R_O_mul) begin
                    a11 <= mul_out;
                    state <= 11;
                end else begin
                    state <= state;
                end
            end
            
            11:
            begin
                MUL_in (a, a11);
                state <= 12;
            end
            
            12:
            begin
                R_I_mul <= 0;
                if (R_O_mul) begin
                    a1 <= mul_out;
                    state <= 13;
                end else begin
                    state <= state;
                end
            end
            
            13:
            begin
                MUL_in (b, x1);
                state <= 14;
            end
            
            14: 
            begin
                R_I_mul <= 0;
                if (R_O_mul) begin
                    b1 <= mul_out;
                    state <= 15;
                end else begin
                    state <= state;
                end
            end
            
            15:
            begin
                SUM_in (a1, b1);
                state <= 16;
            end
    
            16:
            begin
                R_I_sum <= 0;
                if (R_O_sum) begin
                    fb1 <= sum_out;
                    state <= 17;
                end else begin
                    state <= state;
                end
            end
            
            17:
            begin
                SUM_in (fb1, c);
                state <= 18;
            end
    
            18:
            begin
                R_I_sum <= 0;
                if (R_O_sum) begin
                    fb <= sum_out;
                    MUL_in (x, x);
                    state <= 19;
                end else begin
                    state <= state;
                end
            end
    
            19:
            begin
                R_I_mul <= 0;
                if (R_O_mul) begin
                    a11 <= mul_out;
                    state <= 20;
                end else begin
                    state <= state;
                end
            end
            
            20:
            begin
                MUL_in (a, a11);
                state <= 21;
            end
    
            21:
            begin
                R_I_mul <= 0;
                if (R_O_mul) begin
                    a1 <= mul_out;
                    state <= 22;
                end else begin
                    state <= state;
                end
            end
            
            22:
            begin
                MUL_in (b, x);
                state <= 23;
            end
            
            23:
            begin
                R_I_mul <= 0;
                if (R_O_mul) begin
                    b1 <= mul_out;
                    state <= 24;
                end else begin
                    state <= state;
                end
            end
            
            24:
            begin
                SUM_in (a1, b1);
                state <= 25;
            end
    
            25:
            begin
                R_I_sum <= 0;
                if (R_O_sum) begin
                    fx1 <= sum_out;
                    state <= 26;
                end else begin
                    state <= state;
                end
            end
            
            26:
            begin
                SUM_in (fx1, c);
                state <= 27;
            end
    
            27:
            begin
                R_I_sum <= 0;
                if (R_O_sum) begin
                    fx <= sum_out;
                    state <= 28;
                end else begin
                    state <= state;
                end
            end
            
            28:
            begin
                SUM_in (fb, {~fx[15], fx[14:0]});
                state <= 29;
            end
    
            29:
            begin
                R_I_sum <= 0;
                if (R_O_sum) begin
                    denum <= sum_out;
                    state <= 30;
                end else begin
                    state <= state;
                end
            end
    
            30: if (denum == 0) begin
                    R_E <= 2;
                    R_O <= 1;
                    state <= 0;
                end else begin
                    DIV_in (num, denum);
                    state <= 31;
                end
    
            31:
            begin
                R_I_div <= 0;
                if (R_O_div) begin
                    drob <= div_out;
                    state <= 32;
                end else begin
                    state <= state;
                end
            end
            
            32:
            begin
                MUL_in (drob, fx);
                state <= 33;
            end
    
            33:
            begin
                R_I_mul <= 0;
                if (R_O_mul) begin
                    tmp <= mul_out;
                    state <= 34;
                end else begin
                    state <= state;
                end
            end
            
            34:
            begin
                SUM_in (x, {~tmp[15], tmp[14:0]});
                state <= 35;
            end
    
            35: 
            begin
                R_I_sum <= 0;
                if (R_O_sum) begin
                    x <= sum_out;
                    state <= 36;
                end else begin
                    state <= state;
                end
            end
            
            36:
            begin
                SUM_in (x, {~px[15], px[14:0]});
                state <= 37;
            end
    
            37: 
            begin
                R_I_sum <= 0;
                if (R_O_sum) begin
                    dx <= sum_out;
                    //$display("dx=%d", dx);
                    state <= 38;
                end else begin
                    state <= state;
                end
            end
    
            38: if (dx == 0) begin
                    R_E <= 0;
                    result <= x;
                    R_O <= 1;
                    state <= 0;
                end else begin
                    state <= 7;
                end
    
            default:
                state <= state;
        endcase
    end
end

assign data_out = result;
assign a_ = a;
assign b_ = b;
assign c_ = c;

begin // operators import
SUM SUM(
    .clk(clk),
    .reset(reset_sum),
    .a_in(a_sum),
    .b_in(b_sum),
    .z_out(sum_out),
    .R_I(R_I_sum),
    .R_O(R_O_sum),
    .state(state_sum));
    
MUL MUL(
    .clk(clk),
    .reset(reset_mul),
    .a_in(a_mul),
    .b_in(b_mul),
    .z_out(mul_out),
    .R_I(R_I_mul),
    .R_O(R_O_mul),
    .state(state_mul));
    
DIV DIV(
    .clk(clk),
    .reset(reset_div),
    .a_in(a_div),
    .b_in(b_div),
    .z_out(div_out),
    .R_I(R_I_div),
    .R_O(R_O_div),
    .state(state_div));
end

task SUM_in (input [15:0] s1, s2);
begin
    a_sum = s1;
    b_sum = s2;
    R_I_sum = 1;
end
endtask

task MUL_in (input [15:0] m1, m2);
begin
    a_mul = m1;
    b_mul = m2;
    R_I_mul = 1;
end
endtask

task DIV_in(input [15:0] d1, d2);
begin
    a_div = d1;
    b_div = d2;
    R_I_div = 1;
end
endtask

endmodule
