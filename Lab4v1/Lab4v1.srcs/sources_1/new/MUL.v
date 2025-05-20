`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 28.03.2025 11:44:56
// Design Name: 
// Module Name: MULT
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


module MUL(
    input [15:0] a_in, b_in,
    input clk, reset, R_I,
    output reg [15:0] z_out,
    output reg [10:0] a_m, b_m, 
    output reg [10:0] z_m,
    output reg R_O,
    output reg [3:0] state
    );
    
reg [15:0] z;
reg [21:0] product;
reg [5:0] a_e, b_e, z_e;
reg a_s, b_s, z_s;
reg guard, round_bit, sticky;

parameter get         = 4'd0,
          multiply_0  = 4'd1,
          multiply_1  = 4'd2,
          normalise_1 = 4'd3,
          normalise_2 = 4'd4,
          round       = 4'd5,
          pack        = 4'd6,
          put_z       = 4'd7;
          
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
                a_m <= {1'b1, a_in[9:0]};
                b_m <= {1'b1, b_in[9:0]};
                a_e <= a_in[14:10] - 15;
                b_e <= b_in[14:10] - 15;
                a_s <= a_in[15];
                b_s <= b_in[15];
                state <= multiply_0;
            end
        end
        
        multiply_0:
        begin
            z_s <= a_s ^ b_s;
            z_e <= a_e + b_e + 1;
            product <= a_m * b_m;
            state <= multiply_1;
        end
        
        multiply_1:
        begin
            z_m <= product[21:11];
            guard <= product[10];
            round_bit <= product[9];
            sticky <= (product[8:0] != 0);
            state <= normalise_1;
        end
        
        normalise_1:
        begin
            if (z_m[10] == 0) begin
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
