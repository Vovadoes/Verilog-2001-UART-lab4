`timescale 1ns / 1ps


module ASCII_To_HEX (
    input  wire [7:0] ascii_in,
    output reg  [3:0] hex_out
);
    always @(*)
    begin
        case (ascii_in)
            // Цифры 0-9
            8'h30: hex_out = 4'h0;
            8'h31: hex_out = 4'h1;
            8'h32: hex_out = 4'h2;
            8'h33: hex_out = 4'h3;
            8'h34: hex_out = 4'h4;
            8'h35: hex_out = 4'h5;
            8'h36: hex_out = 4'h6;
            8'h37: hex_out = 4'h7;
            8'h38: hex_out = 4'h8;
            8'h39: hex_out = 4'h9;

            // Заглавные буквы A-F
            8'h41: hex_out = 4'hA;
            8'h42: hex_out = 4'hB;
            8'h43: hex_out = 4'hC;
            8'h44: hex_out = 4'hD;
            8'h45: hex_out = 4'hE;
            8'h46: hex_out = 4'hF;

            // Строчные буквы a-f
            8'h61: hex_out = 4'hA;
            8'h62: hex_out = 4'hB;
            8'h63: hex_out = 4'hC;
            8'h64: hex_out = 4'hD;
            8'h65: hex_out = 4'hE;
            8'h66: hex_out = 4'hF;

            // Значение по умолчанию (ошибка/неизвестный символ)
            default: hex_out = 4'h0;
        endcase
    end
endmodule
