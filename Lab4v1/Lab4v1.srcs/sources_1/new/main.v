`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 02/19/2025 10:24:32 PM
// Design Name: 
// Module Name: main
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

module main#(
    parameter MOD_DELITEL = 16384
)(
    input clk,
    input PS2_clk,
    input inpu,
    output [7:0] AN,
    output [6:0] SEG
);

reg CLOCK_ENABLE = 0;
always @(posedge clk)
    CLOCK_ENABLE <= ~CLOCK_ENABLE;

reg [31:0] shift_register;
reg [7:0] an_mask;

wire clk_div_out;

reg reset = 0;
reg [1:0] R_I = 2'b0;
reg [15:0] data_in;
wire [15:0] data_out, x, new_x, a, b, c;
wire [15:0] sum_out, mul_out, div_out;
wire R_O_sum, R_O_mul, R_O_div;
wire [15:0] a_sum, b_sum, a_mul, b_mul, a_div, b_div;
wire [6:0] a_state;
wire [1:0] R_E;
wire R_O;
wire PS2_R_O;
reg [6:0] cnt;
reg [2:0] state;// new_state;
wire [3:0] out;
wire [1:0] flags;
reg [15:0] buffer_in = 0;

initial
begin
    R_I <= 0;
    state <= 0;
    an_mask <= 8'b01110000;
    data_in <= 0;
end

always@(posedge PS2_R_O)
begin
    if (flags == 2'b1)
        buffer_in <= {buffer_in[11:0], out[3:0]};
    else
        buffer_in <= buffer_in;
end

always@(posedge clk)
begin
    case(state)
        0:
        begin
            shift_register <= {4'ha, 12'b0, buffer_in};
            R_I <= 0;
            if (flags == 2'd2 && PS2_R_O) begin
                data_in <= buffer_in;
                state <= 1;
                an_mask <= 8'b01110000;
            end else begin
                data_in <= data_in;
                an_mask <= an_mask;
                state <= state;
            end
        end
        
        1:
        begin
            R_I <= 1;
            state <= 2;
        end
        
        2:
        begin
            R_I <= 0;
            shift_register <= {4'hb, 12'b0, buffer_in};
            if (flags == 2'd2 && PS2_R_O) begin
                data_in <= buffer_in;
                state <= 3;
                an_mask <= 8'b01110000;
            end else begin
                data_in <= data_in;
                an_mask <= an_mask;
                state <= state;
            end
        end
        
        3:
        begin
            R_I <= 2;
            state <= 4;
        end

        4:
        begin
            R_I <= 0;
            shift_register <= {4'hc, 12'b0, buffer_in};
            if (flags == 2'd2 && PS2_R_O) begin
                data_in <= buffer_in;
                state <= 5;
                an_mask <= 8'b11111111;
            end else begin
                data_in <= data_in;
                an_mask <= an_mask;
                state <= state;
            end
        end
        
        5:
        begin
            R_I <= 3;
            state <= 6;
        end
        
        6:
        begin
            R_I <= 0;
            an_mask <= 8'b11111100;
            shift_register <= a_state;
            if (R_O) begin
                if (R_E) begin
                    an_mask <= 8'b11111010;
                    shift_register <= {20'b0, 4'he, 6'b0, R_E};
                end else begin
                    an_mask <= 8'b11110000;
                    shift_register <= {16'b0, data_out};
                end
                state <= 7;
            end else begin
                shift_register <= shift_register;
                an_mask <= an_mask;
                state <= state;
            end
        end
        
        7:
        if (flags == 2'd2 && PS2_R_O) begin
            an_mask <= 8'b01110000;
            shift_register <= {4'ha, 12'b0, buffer_in};
            state <= 0;
            R_I <= 0;
        end else begin
            shift_register <= shift_register;
            an_mask <= an_mask;
            R_I <= R_I;
            state <= state;
        end
        
    endcase
end

//Module imports
PS2_Manager m_m(
    .clk(clk),
    .PS2_dat(PS2_dat),
    .PS2_clk(PS2_clk),
    .R_O(PS2_R_O),
    .out(out),
    .flags(flags)
);

delitel #(.mod(MOD_DELITEL)) clk_div1 ( // 8192
    .clk(clk),
    .out(clk_div_out)
);

SevenSegmentLED seg(
    .clk(clk_div_out),
    .RESET(1'b0),
    .NUMBER(shift_register),
    .AN_MASK(an_mask),
    .AN(AN),
    .SEG(SEG)
);

automat_2 automat(.clk(clk), .reset(reset), .R_I(R_I), .data_in(data_in), .data_out(data_out), .R_E(R_E), .R_O(R_O), .state(a_state), .x(x), //.new_x(new_x),
                .a_(a), .b_(b), .c_(c), .sum_out(sum_out), .mul_out(mul_out), .div_out(div_out), .R_O_sum(R_O_sum), .R_O_mul(R_O_mul), .R_O_div(R_O_div),
                .a_sum(a_sum), .b_sum(b_sum), .a_mul(a_mul), .b_mul(b_mul), .a_div(a_div), .b_div(b_div));
       
vio_0 vio(
    .clk(clk),
    .probe_in0(state),
    .probe_in1(a_state),
    .probe_in2(R_O),
    .probe_in3(buffer_in),
    .probe_in4(data_in),
    .probe_in5(R_I),
    .probe_in6(flags),
    .probe_in7(a),
    .probe_in8(b),
    .probe_in9(c),
    .probe_in10(PS2_clk),
    .probe_in11(PS2_dat),
    .probe_in12(out)
    
);
endmodule
