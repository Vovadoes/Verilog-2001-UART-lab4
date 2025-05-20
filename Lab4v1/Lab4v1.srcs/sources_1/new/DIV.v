`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 29.03.2025 18:00:53
// Design Name: 
// Module Name: DIV
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


module DIV(
    input [15:0] a_in, b_in,
    input clk, reset, R_I,
    output reg [15:0] z_out,
    output reg [10:0] a_m, b_m, 
    output reg [10:0] z_m,
    output reg R_O,
    output reg [3:0] state,
    output reg [25:0] quotient, divisor, dividend, remainder
    );
    
reg [15:0] z;
reg [27:0] product;
reg [5:0] a_e, b_e, z_e;
reg a_s, b_s, z_s;
reg guard, round_bit, sticky;
reg [5:0] count;

parameter get         = 4'd0,
          normalise_a = 4'd1,
          normalise_b = 4'd2,
          divide_0    = 4'd3,
          divide_1    = 4'd4,
          divide_2    = 4'd5,
          divide_3    = 4'd6,
          normalise_1 = 4'd7,
          normalise_2 = 4'd8,
          round       = 4'd9,
          pack        = 4'd10,
          put_z       = 4'd11;
          
initial
begin
    state <= 0;
    R_O <= 0;
end

//always@(posedge clk)
//begin
//    if (reset)
//        state <= 0;
//    else
//        new_count <= count;
//        state <= new_state;
//        remainder <= new_remainder;
//        dividend <= new_dividend;
//        quotient <= new_quotient;
//end

always@(posedge clk)
begin
    case(state)
        get:
        begin
            R_O <= 0;
            if (R_I == 1) begin
                a_m <= {1'b1, a_in[9:0]};
                b_m <= {1'b1, b_in[9:0]};
                a_e <= a_in[14:10] - 15;
                b_e <= b_in[14:10] - 15;
                a_s <= a_in[15];
                b_s <= b_in[15];
                state <= normalise_a;
            end
        end
        
        normalise_a:
        begin
            if (a_m[10]) begin
                state <= normalise_b;
            end else begin
                a_m <= a_m << 1;
                a_e <= a_e - 1;
            end
        end

        normalise_b:
        begin
            if (b_m[10]) begin
                state <= divide_0;
            end else begin
                b_m <= b_m << 1;
                b_e <= b_e - 1;
            end
        end
        
        divide_0:
        begin
            z_s <= a_s ^ b_s;
            z_e <= a_e - b_e;
            quotient <= 0;
            remainder <= 0;
            count <= 0;
            dividend <= a_m << 15;
            divisor <= b_m;
            state <= divide_1;
        end

        divide_1:
        begin
            remainder <= remainder << 1;
            remainder[0] <= dividend[25];
            dividend <= dividend << 1;
            quotient <= quotient << 1;
            state <= divide_2;
        end
        
        divide_2:
        begin
            if (remainder >= divisor) begin
                quotient[0] <= 1;
                remainder <= remainder - divisor;
            end
            if (count == 24) begin
                state <= divide_3;
            end else begin
                count <= count + 1;
                state <= divide_1;
            end
        end
        
        divide_3:
        begin
            z_m <= quotient[14:4];
            guard <= quotient[3];
            round_bit <= quotient[2];
            sticky <= quotient[1:0] != 0 | (remainder != 0);
            state <= normalise_1;
        end
        
        normalise_1:
        begin
            if (z_m[10] == 0 && $signed(z_e) > -14) begin
                z_e <= z_e - 1;
                z_m <= z_m << 1;
                z_m[0] <= guard;
                guard <= round_bit;
                round_bit <= 0;
            end else begin
                state <= normalise_2;
            end
        end
        
        normalise_2:
        begin
            if ($signed(z_e) < -14) begin
                z_e <= z_e + 1;
                z_m <= z_m >> 1;
                guard <= z_m[0];
                round_bit <= guard;
                sticky <= sticky | round_bit;
            end else begin
                state <= round;
            end
        end
        
        round:
        begin
            if (guard && (round_bit | sticky | z_m[0])) begin
                z_m <= z_m + 1;
                if (z_m == 11'h7ff) begin
                    z_e <= z_e + 1;
                end
            end
            state <= pack;
        end

        pack:
        begin
            z[9:0] <= z_m[9:0];
            z[14:10] <= z_e[5:0] + 15;
            z[15] <= z_s;
            if ($signed(z_e) == -14 && z_m[10] == 0) begin
                z[14:10] <= 0;
            end
            //if overflow occurs, return inf
            if ($signed(z_e) > 15) begin
                z[9:0] <= 0;
                z[14:10] <= 31;
                z[15] <= z_s;
            end
            state <= put_z;
        end
        
        put_z:
        begin
            R_O <= 1;
            z_out <= z;
            state <= get;
        end
        
    endcase
end
endmodule
