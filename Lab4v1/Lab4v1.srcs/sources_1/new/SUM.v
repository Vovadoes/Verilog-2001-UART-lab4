`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 21.03.2025 11:04:03
// Design Name: 
// Module Name: sum
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


module SUM(
    input [15:0] a_in, b_in,
    input clk, reset, R_I,
    output reg [15:0] z_out,
    output reg [13:0] a_m, b_m, 
    output reg [10:0] z_m,
    output reg R_O,
    output reg [3:0] state
    );

reg [15:0] z;
reg [14:0] sum_m;
reg [5:0] a_e, b_e, z_e;
reg a_s, b_s, z_s;
reg guard, round_bit, sticky;

parameter get         = 4'd0,
          align       = 4'd1,
          add_0       = 4'd2,
          add_1       = 4'd3,
          normalise_1 = 4'd4,
          normalise_2 = 4'd5,
          round       = 4'd6,
          pack        = 4'd7,
          put_z       = 4'd8;
          
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
//        state <= new_state;
//end

always@(posedge clk)
begin
    case(state)
        get:
        begin
            R_O <= 0;
            if (R_I == 1) begin
                a_m <= {1'b1, a_in[9:0], 3'd0};
                b_m <= {1'b1, b_in[9:0], 3'd0};
                a_e <= a_in[14:10] - 15;
                b_e <= b_in[14:10] - 15;
                a_s <= a_in[15];
                b_s <= b_in[15];
                state <= align;
            end
        end
        
        align:
        begin
            if ($signed(a_e) > $signed(b_e)) begin
                b_e <= b_e + 1;
                b_m <= b_m >> 1;
                //b_m[0] <= b_m[0] | b_m[1];
            end else if ($signed(a_e) < $signed(b_e)) begin
                a_e <= a_e + 1;
                a_m <= a_m >> 1;
                //a_m[0] <= a_m[0] | a_m[1];
            end else begin
                state <= add_0;
            end
        end
        
        add_0:
        begin
            z_e <= a_e;
            if (a_s == b_s) begin
                sum_m <= a_m + b_m;
                z_s <= a_s;
            end
            else begin
                if (a_m >= b_m) begin
                    sum_m <= a_m - b_m;
                    z_s <= a_s;
                end 
                else begin
                    sum_m <= b_m - a_m;
                    z_s <= b_s;
                end
            end
            state <= add_1;
        end
        
        add_1:
        begin
            //$display("%b", sum);
            if (sum_m[14]) begin
                z_m <= sum_m[14:4];
                guard <= sum_m[3];
                round_bit <= sum_m[2];
                sticky <= sum_m[1] | sum_m[0];
                z_e <= z_e + 1;
            end else begin
                z_m <= sum_m[13:3];
                guard <= sum_m[2];
                round_bit <= sum_m[1];
                sticky <= sum_m[0];
            end
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
                if (z_m == 10'h3ff) begin
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
            if ($signed(z_e) == -14 && z_m[10:0] == 10'h0) begin
                z[15] <= 1'b0; // FIX SIGN BUG: -a + a = +0.
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
