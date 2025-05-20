`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 02/19/2025 10:14:06 PM
// Design Name: 
// Module Name: SevenSegmentLED
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


module SevenSegmentLED (
input clk,
input RESET,
input [31:0] NUMBER, // Входное число
input [7:0] AN_MASK, // Маска отображения 7-сегментных индикаторов
output [7:0] AN, // шина разрешающих входов анодов для всех индикаторов
output reg [6:0] SEG // шина катодов для одного индикатора
);
reg [7:0] AN_REG = 0;
assign AN = AN_REG | AN_MASK;
// Значение на счётчике обозначает номер разряда входного числа (номер индикатора)
// который отображается (3-х разрядный, так как только 8 цифр можно отобразить)
reg [2:0] digit_counter;
// Разветвитель входящего числа по группам из 4-х бит
wire [3:0] NUMBER_SPLITTER [0:7]; // = {NUMBER[3:0], NUMBER[7:4], NUMBER[11:8], NUMBER[15:12], NUMBER[19:16], NUMBER[23:20], NUMBER[27:24], NUMBER[31:28]};
genvar i;
generate
for (i = 0; i < 8; i = i + 1)
begin
assign NUMBER_SPLITTER[i] = NUMBER[((i+1)*4-1)-:4];
end
endgenerate
initial begin
digit_counter = 0;
end
// Блок управления счётчиком индикаторов
always @(posedge clk or posedge RESET)
digit_counter <= RESET ? 0 : digit_counter + 3'b1;
/*
В силу особенностей реализации на плате 7-сегментных индикаторов,
все индикаторы имеют общий анод, который выбирает индикатор, а
катоды соединены с общей шиной и подключены к каждому индикатору
*/
always @ (digit_counter)
begin
/*
Установка подсветки 7-сегментного индикатора
в зависимости от дешифрованной цифры
*/
case (NUMBER_SPLITTER[digit_counter])
4'h0: SEG <= 7'b1000000;
4'h1: SEG <= 7'b1111001;
4'h2: SEG <= 7'b0100100;
4'h3: SEG <= 7'b0110000;
4'h4: SEG <= 7'b0011001;
4'h5: SEG <= 7'b0010010;
4'h6: SEG <= 7'b0000010;
4'h7: SEG <= 7'b1111000;
4'h8: SEG <= 7'b0000000;
4'h9: SEG <= 7'b0010000;
4'ha: SEG <= 7'b0001000;
4'hb: SEG <= 7'b0000011;
4'hc: SEG <= 7'b1000110;
4'hd: SEG <= 7'b0100001;
4'he: SEG <= 7'b0000110;
4'hf: SEG <= 7'b0001110;
default: SEG <= 7'b1111111;
endcase
/*
Поскольку у всех 7-сегментных индикаторов один общий анод,
то необходимо, в зависимости от номера разряда, который
отображается в текущий дискретный момент времени, подать
соответствующий сигнал на нужный индикатор.
Чтобы осветить сегмент, анод должен находиться в высоком уровне, а катод - в низком.
Однако, поскольку используются транзисторы для подачи достаточного тока
в общую точку анода, вход разрешения для анода инвертируется.
*/
//AN_REG <= ~(8'd1 << digit_counter);
case (digit_counter)
3'd0: AN_REG <= 8'b11111110;
3'd1: AN_REG <= 8'b11111101;
3'd2: AN_REG <= 8'b11111011;
3'd3: AN_REG <= 8'b11110111;
3'd4: AN_REG <= 8'b11101111;
3'd5: AN_REG <= 8'b11011111;
3'd6: AN_REG <= 8'b10111111;
3'd7: AN_REG <= 8'b01111111;
default: AN_REG <= 8'b11111111;
endcase
end
endmodule
