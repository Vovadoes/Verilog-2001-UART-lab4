`timescale 1ns / 1ns

module UART #
(
    localparam CLOCK_RATE = 100_000_000, // Частота ПЛИС XC7A100T-1CSG324 семейства Artix-7 (в Гц)
    localparam BAUD_RATE = 9600,	// Скорость передачи данных по UART (в бод)
    localparam ERROR_COUNT = 3, // Количество возможных ошибок основного автомата
    localparam DIGIT_COUNT = 4 // Разрядность входных данных, представленных в 16-ричном виде
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
wire reset = 1'b0;

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
fsm #(
    .DIGIT_COUNT(DIGIT_COUNT),
    .ERROR_COUNT(ERROR_COUNT)
) FSM(
	.clk(clk),
	.R_I(FSM_Ready_Input),
	.reset(0),
	.R_O(FSM_Ready_Output),
	.dataIn(FSM_Data_Input),
	.dataOut(FSM_Data_Output),
	.error(FSM_Error_Output)
);
endmodule
