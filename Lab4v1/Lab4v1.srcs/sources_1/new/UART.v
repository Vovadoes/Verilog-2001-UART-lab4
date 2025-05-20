`timescale 1ns / 1ns

module UART #
(
    localparam CLOCK_RATE = 100_000_000, // Частота ПЛИС XC7A100T-1CSG324 семейства Artix-7 (в Гц)
    localparam BAUD_RATE = 9600,	// Скорость передачи данных по UART (в бод)
    localparam ERROR_COUNT = 3, // Количество возможных ошибок основного автомата
    localparam DIGIT_COUNT = 4, // Разрядность входных данных, представленных в 16-ричном виде
    localparam MOD_DELITEL = 16000
)
(
	input clk,		// Синхросигнал
	input RsRx,	 	// Бит принимаемых данных (UART_RX)
	output RsTx 	// Бит отправляемых данных (UART_TX)	
);

// FSM
wire [15:0] FSM_Data_Input;	  // Шина входных данных автомата
wire FSM_Ready_Input;		  // Сигнал о том, что данные на входе автомата сформированы
wire FSM_Ready_Output;		  // Сигнал о том, что данные на выходе автомата сформированы
wire [15:0] FSM_Data_Output;  // Шина выходных данных автомата
wire [1:0] FSM_Error_Output;  // Шина ошибок на выходе автомата

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
reg [6:0] cnt;
reg [2:0] state;// new_state;
wire [1:0] flags;
reg [15:0] buffer_in = 0;

initial
begin
    R_I <= 0;
    state <= 0;
    an_mask <= 8'b01110000;
    data_in <= 0;
end

always@(posedge clk)
begin
    case(state)
        0:
        begin
            shift_register <= {4'ha, 12'b0, FSM_Data_Input};
            R_I <= 0;
            if (FSM_Ready_Input) begin
                data_in <= FSM_Data_Input;
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
            shift_register <= {4'hb, 12'b0, FSM_Data_Input};
            if (FSM_Ready_Input) begin
                data_in <= FSM_Data_Input;
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
            shift_register <= {4'hc, 12'b0, FSM_Data_Input};
            if (FSM_Ready_Input) begin
                data_in <= FSM_Data_Input;
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
            if (FSM_Ready_Output) begin
                if (FSM_Error_Output) begin
                    an_mask <= 8'b11111010;
                    shift_register <= {20'b0, 4'he, 6'b0, FSM_Error_Output};
                end else begin
                    an_mask <= 8'b11110000;
                    shift_register <= {16'b0, FSM_Data_Output};
                end
                state <= 7;
            end else begin
                shift_register <= shift_register;
                an_mask <= an_mask;
                state <= state;
            end
        end
        
        7:
        if (FSM_Ready_Output) begin
            an_mask <= 8'b01110000;
            shift_register <= {4'ha, 12'b0, FSM_Data_Input};
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

automat_2 automat(.clk(clk), .reset(reset), .R_I(R_I), .data_in(data_in), .data_out(FSM_Data_Output), .R_E(FSM_Error_Output), .R_O(FSM_Ready_Output), .state(a_state), .x(x), //.new_x(new_x),
                .a_(a), .b_(b), .c_(c), .sum_out(sum_out), .mul_out(mul_out), .div_out(div_out), .R_O_sum(R_O_sum), .R_O_mul(R_O_mul), .R_O_div(R_O_div),
                .a_sum(a_sum), .b_sum(b_sum), .a_mul(a_mul), .b_mul(b_mul), .a_div(a_div), .b_div(b_div));
 

// Автомат, занимающийся менеджментом входных данных с UART
UART_Input_Manager #(.DIGIT_COUNT(DIGIT_COUNT)) uart_input_manager 
(
	.clk(clk), 		// Вход синхросигнала
	.reset(reset),
	.RsRx(RsRx),
	.out(FSM_Data_Input),// Выход со значением для входа основного автомата
	.ready_out(FSM_Ready_Input)	// Выход - сигнал о том, что данные на выходе <number_out> сформированы
);
// Автомат, занимающийся менеджментом выходных данных на UART
UART_Output_Manager #(.ERROR_COUNT(ERROR_COUNT)) uart_output_manager 
(
	.clk(clk), // Вход: Синхросигнал
	.reset(reset),
	.ready_in(FSM_Ready_Output), // Вход: сигнал о том, что данные для отправки по UART сформированы
	.data_in(FSM_Data_Output),   // Вход: данные для отправки по UART
	.error_in(FSM_Error_Output), // Вход: данные об ошибках для отправки по UART
	.RsTx(RsTx)
);

//fsm #(
//    .DIGIT_COUNT(DIGIT_COUNT),
//    .ERROR_COUNT(ERROR_COUNT)
//) FSM(
//	.clk(clk),
//	.R_I(FSM_Ready_Input),
//	.reset(0),
//	.R_O(FSM_Ready_Output),
//	.dataIn(FSM_Data_Input),
//	.dataOut(FSM_Data_Output),
//	.error(FSM_Error_Output)
//);

//main main(
//    .clk(clk),
//    input PS2_clk,
//    input PS2_dat,
//    output [7:0] AN,
//    output [6:0] SEG
//);

endmodule
