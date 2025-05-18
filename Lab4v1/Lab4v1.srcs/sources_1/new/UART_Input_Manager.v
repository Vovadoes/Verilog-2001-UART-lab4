`timescale 1ns / 1ps

module UART_Input_Manager #
(
	CLOCK_RATE = 100_000_000, // Частота ПЛИС XC7A100T-1CSG324C семейства Artix-7 (в Гц)
    BAUD_RATE = 9600,		  // Скорость передачи данных по UART (в бод)
	DIGIT_COUNT = 4           // Разрядность входных данных, представленных в 16-ричном виде
)
(
	input clk, 					 // Синхросигнал
	input reset,                 // Сигнал сброса
	input RsRx,
	
	output reg [DIGIT_COUNT * 4 - 1 : 0] out, // Принятое декодированное число для отправки на основной автомат
	output reg ready_out					  // Сигнал о том, что выше упомянутое число сформировано
);
// UART_RX
wire UART_RX_Ready_Out;		  // Сигнал о том, что автоматом (UART_RX) был принят один пакет данных
wire [7:0] UART_RX_Data_Out;  // Принятый пакет данных (находится на выходе автомата UART_RX)
// Автомат, занимающийся приёмом (receive) данных по UART
localparam RX_DATA_SIZE = 8;
UART_RX #(.CLOCK_RATE(CLOCK_RATE), .BAUD_RATE(BAUD_RATE)) uart_rx
(
	.clk(clk), 								// Вход: Синхросигнал
	.rx(RsRx), 								// Вход для приёма очередного бита данных с UART
	.UART_RX_Ready_Out(UART_RX_Ready_Out),  // Выход: сигнал о том, что сформирован пакет принятых данных
	.UART_RX_Data_Out(UART_RX_Data_Out)		// Выход: сформированный пакет из входных данных
);

localparam FIFO_MEM_SIZE = 6;
localparam FIFO_DATA_SIZE = RX_DATA_SIZE;

wire FIFO_write_mode;		// регистр сигнала записи данных в буфер FIFO
assign FIFO_write_mode = UART_RX_Ready_Out;
wire [FIFO_DATA_SIZE-1:0] FIFO_data_in;    // входная шина буфера FIFO 
assign FIFO_data_in = UART_RX_Data_Out;

reg FIFO_read_mode;         // регистр сигнала чтения данных из буфера FIFO
wire [FIFO_DATA_SIZE-1:0] FIFO_data_out;    // выходная шина буфера FIFO

wire FIFO_empty;			// сигнал с выхода FIFO о том, что буфер пуст
wire FIFO_full; 			// сигнал с выхода FIFO о том, что буфер полон
wire FIFO_valid;            // сигнал с выхода FIFO о том, что значение на выходе валидно

// Буфер FIFO
SimpleFIFO #(
	.MEM_SIZE(FIFO_MEM_SIZE),	
    .DATA_SIZE(FIFO_DATA_SIZE)
) 
simpleFIFO(
    .reset(reset),
    .clk(clk),
    .enable(1'b1),
    .read_mode(FIFO_read_mode),
    .write_mode(FIFO_write_mode),
    .data_in(FIFO_data_in),
    .data_out(FIFO_data_out),
    .full(FIFO_full),
    .empty(FIFO_empty),
    .valid(FIFO_valid)
);

// Дешифратор, преобразующий ASCII код 16-ричного разряда в 16-ричный разряд
localparam ASCII_SIZE = 8;
localparam HEX_SIZE = 4;
wire [ASCII_SIZE-1:0] ASCII_in = FIFO_data_out;
wire [HEX_SIZE-1:0] HEX_out;
ASCII_To_HEX a1(ASCII_in, HEX_out);

// Автомат
//reg state; // Регистр текущего состояния автомата
//localparam RESET = 0, READ_FIFO = 1;
localparam CR = 8'h0D;

// Стартовая инициализация автомата
initial 
begin
    FIFO_read_mode <= 1;
	out <= 0;
	ready_out <= 0;
end

// Блок обработки текущего состояния
always@(posedge clk)
begin
    if (reset)
        begin 
            ready_out <= 0;
            out <= 0;        
            FIFO_read_mode <= 1;
        end
    else
        begin
            // Буфер FIFO не пустой
            if (FIFO_valid)
                begin
                    // На выходной шине данных FIFO завершающая 
                    // последовательность (CR - перевод каретки)  
                    if (FIFO_data_out == CR)
                        ready_out <= 1;
                    else
                        out <= {out[DIGIT_COUNT * 4 - 5 : 0], HEX_out};
                end
            else    
                ready_out <= 0;
        end         
end

endmodule

