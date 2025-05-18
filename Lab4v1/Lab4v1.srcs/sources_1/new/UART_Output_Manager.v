`timescale 1ns / 1ps

// Октет ≡ Пакет ≡ Байт ≡ Символ

module UART_Output_Manager #
(
	ERROR_COUNT = 2, // Количество ошибок
	RESULT_SIZE = 4, // Количество разрядов входного числа, представленного в 16-й СС 
	CLOCK_RATE = 100_000_000, // Частота ПЛИС XC7A100T-1CSG324C семейства Artix-7 (в Гц)
    BAUD_RATE = 9600,		  // Скорость передачи данных по UART (в бод)
    localparam ASCII_SIZE = 8,
    localparam HEX_SIZE = 4,
    localparam ERROR_IN_BIT_SIZE = $clog2(ERROR_COUNT)
)
(
	input clk, // Синхросигнал
	input reset,
	
	input ready_in,								// сигнал о том, что данные для отправки по UART сформированы
	input [RESULT_SIZE * HEX_SIZE-1:0] data_in,	// данные для отправки по UART	
	input [ERROR_IN_BIT_SIZE-1:0] error_in,   	// данные об ошибках для отправки по UART
	
	output RsTx	  
);

// Количество шестнадцатиричных разрядов ошибки
localparam ERROR_HEX_SIZE = (ERROR_IN_BIT_SIZE % HEX_SIZE == 0) 
                          ? (ERROR_IN_BIT_SIZE / HEX_SIZE) 
                          : (ERROR_IN_BIT_SIZE / HEX_SIZE + 1);

// Размер отправляемеого значения ошибки
localparam ERROR_HEX_BIT_SIZE = HEX_SIZE * ERROR_HEX_SIZE;
//
wire [ERROR_HEX_BIT_SIZE - 1 : 0] error_to_send = 
{
    {(ERROR_HEX_BIT_SIZE - ERROR_IN_BIT_SIZE){1'b0}},
    error_in
};

wire [RESULT_SIZE * ASCII_SIZE - 1 : 0] tmp_data; // Провод для данных с выхода преобразователя результата
wire [ERROR_HEX_SIZE * ASCII_SIZE - 1 : 0] tmp_error; // Провод для данных с выхода преобразователя ошибки

/* -------------------------------------------- *
 *  Преобразователь входных значений            *
 *  RESULT_SIZE - число дешифраторов результата *
 *  ERROR_HEX_SIZE - число дешифраторов ошибки  *
 * -------------------------------------------- */
genvar g;
generate
	// Преобразователь результата
	for (g = 0; g < RESULT_SIZE; g = g + 1)
	begin
		HEX_To_ASCII hr( 
              data_in[HEX_SIZE * (RESULT_SIZE - g) - 1 -: HEX_SIZE], 
              tmp_data[ASCII_SIZE * (RESULT_SIZE - g) - 1 -: ASCII_SIZE] 
		);
	end
	
	// Преобразователь ошибки
	for (g = 0; g < ERROR_HEX_SIZE; g = g + 1)
	begin
		HEX_To_ASCII hr( 
		      error_to_send[HEX_SIZE * (ERROR_HEX_SIZE - g) - 1 -: HEX_SIZE], 
		      tmp_error[ASCII_SIZE * (ERROR_HEX_SIZE - g) - 1 -: ASCII_SIZE]
		);
	end
endgenerate
/*
* ------------------------------------------------------------ *
*  Автомат формирования пакетов данных для отправки по UART    *
* ------------------------------------------------------------ *
*/

reg [2:0] state; // Регистр текущего состояния автомата
localparam RESET = 0, PREPARE_DATA = 1, SEND_DATA = 2;

localparam RESULT_TITLE_SIZE = 8;
localparam RESULT_CHAR_ARRAY_SIZE = RESULT_TITLE_SIZE + RESULT_SIZE + 2;   
reg [ASCII_SIZE * RESULT_CHAR_ARRAY_SIZE - 1:0] result_char_array;

localparam ERROR_TITLE_SIZE = 7;
localparam ERROR_AFTER_SIZE = 1;
localparam ERROR_CHAR_ARRAY_SIZE = ERROR_TITLE_SIZE + ERROR_HEX_SIZE + ERROR_AFTER_SIZE + 2;
reg [ASCII_SIZE * ERROR_CHAR_ARRAY_SIZE - 1:0] error_char_array;

localparam END_SEQ_SIZE = 2;  // CR, LF

reg [3:0] char_counter;				// Счётчик символов в строке
reg [3:0] char_max_index;			// Индекс элемента памяти, после которого (в сторону увеличения индекса) нет выводимого символа


reg package_ready;
reg [ASCII_SIZE-1:0] package_out; // пакет (сформированный из данных) для отправки по UART

reg error_mode;                   // сигнал о том, что пакет сформирован и готов для отправки по UART

// Стартовая инициализация автомата
integer i;
initial 
begin
	result_char_array[ASCII_SIZE * RESULT_CHAR_ARRAY_SIZE - 1 -: ASCII_SIZE * RESULT_TITLE_SIZE] = "Result: ";
	// Код символа перевода каретки в начало (CR) + Код символа перехода на новую строку  (LF)
	result_char_array[ASCII_SIZE * END_SEQ_SIZE - 1 : 0] = 16'h0D0A; 
	
	error_char_array[ASCII_SIZE * ERROR_CHAR_ARRAY_SIZE - 1 -: ASCII_SIZE * ERROR_TITLE_SIZE] = "Error: ";
	error_char_array[ASCII_SIZE * (END_SEQ_SIZE + ERROR_AFTER_SIZE) - 1 -: ASCII_SIZE * ERROR_AFTER_SIZE] = "!";
	// Код символа перевода каретки в начало (CR) + Код символа перехода на новую строку  (LF)
	error_char_array[ASCII_SIZE * END_SEQ_SIZE - 1 : 0] = 16'h0D0A;
	
	char_counter <= 0;
	char_max_index <= 0;
	
	package_out <= 0;
	package_ready <= 0;
	error_mode <= 0;
	
	state <= RESET; // Установка начального состояния автомата в состояния сброса
end

always@(posedge clk) 
begin: main_block
	case(state) 
		RESET: // Сброс
			begin
				char_counter <= 0;
				char_max_index <= 0;
				package_out <= 0;
	            package_ready <= 0;
	            error_mode <= 0;
				
				state <= PREPARE_DATA;
			end
		PREPARE_DATA: // Формирование строки для отправки
			// Если данные для отправки сформированы
			if (ready_in)
				begin
					// Если результатом работы автомата не является ошибка
					if (error_to_send == 0)
						begin
							// Запись ведётся по октетам дешифрованных данных
							for (i = 0; i < RESULT_SIZE; i = i + 1)
								result_char_array[ASCII_SIZE * (RESULT_CHAR_ARRAY_SIZE - RESULT_TITLE_SIZE - i) - 1 -: ASCII_SIZE] 
									<=  tmp_data[ASCII_SIZE * (RESULT_SIZE - i) - 1 -: ASCII_SIZE];
							char_max_index <= RESULT_CHAR_ARRAY_SIZE - 1;
						end
					// Если результатом работы автомата является ошибка
					else
						begin
							// Запись ведётся по октетам дешифрованных данных
							for(i = 0; i < ERROR_HEX_SIZE; i = i + 1)
								error_char_array[ASCII_SIZE * (ERROR_CHAR_ARRAY_SIZE - ERROR_TITLE_SIZE - i) - 1 -: ASCII_SIZE] 
									<=  tmp_error[ASCII_SIZE * (ERROR_HEX_SIZE - i) - 1 -: ASCII_SIZE];
							char_max_index <= ERROR_CHAR_ARRAY_SIZE - 1;
							error_mode <= 1;
						end
					state <= SEND_DATA;
				end
		
		SEND_DATA: // Отправка строки на вывод по одному символу (байту, октету)
			begin
				package_ready <= 1; // устанавливаем в 1 сигнал о том, что пакет сформирован на выходе
				package_out <= error_mode ? error_char_array[ASCII_SIZE * (ERROR_CHAR_ARRAY_SIZE - char_counter) - 1 -: ASCII_SIZE] : result_char_array[ASCII_SIZE * (RESULT_CHAR_ARRAY_SIZE - char_counter) - 1 -: ASCII_SIZE]; // на выход подаём очередной пакет
				char_counter <= char_counter + 1;
				// Если все символы строки были отправлены
				if (char_counter == char_max_index)
					begin
						state <= RESET;
						//package_ready <= 0; // сообщаем, что больше нет пакетов (символов, байтов, октетов) для отправки
					end
			end
	endcase
end
localparam FIFO_MEM_SIZE = RESULT_CHAR_ARRAY_SIZE > ERROR_CHAR_ARRAY_SIZE
                         ? RESULT_CHAR_ARRAY_SIZE : ERROR_CHAR_ARRAY_SIZE;
localparam FIFO_DATA_SIZE = ASCII_SIZE;
wire FIFO_write_mode;		// регистр сигнала записи данных в буфер FIFO
assign FIFO_write_mode = package_ready;
wire [FIFO_DATA_SIZE-1:0] FIFO_data_in;    // входная шина буфера FIFO 
assign FIFO_data_in = package_out;
wire FIFO_read_mode; // регистр сигнала чтения данных из буфера FIFO
wire [FIFO_DATA_SIZE-1:0] FIFO_data_out;    // выходная шина буфера FIFO
wire FIFO_empty;			// сигнал с выхода FIFO о том, что буфер пуст
wire FIFO_full; 			// сигнал с выхода FIFO о том, что буфер полон
// Буфер FIFO
SimpleFIFO #(
	.MEM_SIZE(FIFO_MEM_SIZE),	
    .DATA_SIZE(FIFO_DATA_SIZE)
) 
simpleFIFO(
    .enable(1'b1),
    .reset(reset),
    .clk(clk),
    .read_mode(FIFO_read_mode),
    .write_mode(FIFO_write_mode),
    .data_in(FIFO_data_in),
    .data_out(FIFO_data_out),
    .full(FIFO_full),
    .empty(FIFO_empty),
    .valid(FIFO_valid)
);

// UART_TX
wire UART_Ready_To_Send;
assign FIFO_read_mode = UART_Ready_To_Send & !FIFO_valid;

wire UART_TX_Ready_In = FIFO_valid; // Сигнал о том, что на входе автомата (UART_TX) сформированы данные для отправки
wire [7:0] UART_TX_Data_In = FIFO_data_out;   // Отправляемый пакет данных (находится на входе автомата UART_TX) 

// Автомат, занимающийся отправкой (transmit) данных по UART
UART_TX #(.CLOCK_RATE(CLOCK_RATE), .BAUD_RATE(BAUD_RATE)) uart_tx
(
	.clk(clk),								// Вход: Синхросигнал								 
	.UART_TX_Ready_In(UART_TX_Ready_In),	// Вход: сигнал о том, что данные на DATA_IN нужно отправить по UART
	.UART_TX_Data_In(UART_TX_Data_In),		// Вход: пакет данных, который нужно отправить по UART
	.idle(UART_Ready_To_Send),
	.tx(RsTx)								// Выход для отправки очередного бита данных по UART
);
endmodule
