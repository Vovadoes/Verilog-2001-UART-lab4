`timescale 1ns / 1ps


module HEX_To_ASCII (
    input  wire [3:0] hex_in,
    output reg  [7:0] ascii_out
);
    always @(*) begin
        case (hex_in)
            4'h0: ascii_out = 8'h30; // '0'
            4'h1: ascii_out = 8'h31; // '1'
            4'h2: ascii_out = 8'h32; // '2'
            4'h3: ascii_out = 8'h33; // '3'
            4'h4: ascii_out = 8'h34; // '4'
            4'h5: ascii_out = 8'h35; // '5'
            4'h6: ascii_out = 8'h36; // '6'
            4'h7: ascii_out = 8'h37; // '7'
            4'h8: ascii_out = 8'h38; // '8'
            4'h9: ascii_out = 8'h39; // '9'
            4'hA: ascii_out = 8'h41; // 'A'
            4'hB: ascii_out = 8'h42; // 'B'
            4'hC: ascii_out = 8'h43; // 'C'
            4'hD: ascii_out = 8'h44; // 'D'
            4'hE: ascii_out = 8'h45; // 'E'
            4'hF: ascii_out = 8'h46; // 'F'
            default: ascii_out = 8'h3F; // '?' - для недопустимых значений
        endcase
    end
endmodule


