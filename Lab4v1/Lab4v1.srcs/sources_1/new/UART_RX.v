module UART_RX #
(
	parameter CLOCK_RATE = 100_000_000, // Частота ПЛИС - по умолчанию, частота XC7A100T-1CSG324C семейства Artix-7 (в Гц)
	parameter BAUD_RATE = 9600			// Скорость передачи данных по UART (в бод)
)
(
	input clk,		// Синхросигнал
	input rx,		// Порт для приёма очередного бита данных с UART
	
	output reg UART_RX_Ready_Out,	// сигнал готовности значения на выходе
	output reg [7:0] UART_RX_Data_Out  // загружаемые данные с порта RX
);
reg [1:0] state; // Регистр текущего состояния автомата
reg [3:0] bit_counter;	// Cчётчик битов		
reg [$clog2(CLOCK_RATE / BAUD_RATE):0] baud_counter;  // Cчётчик частоты передачи UART
reg baud_flag; // Флаг о том, что счётчик синхросигнала стал равен половине такта BAUD_RATE 
localparam RESET = 0, WAIT_START_BIT = 1, LOAD_BIT = 2, WAIT_HALF_RATE = 3;

// Мажоритарный элемент
reg [2:0] major_buf;
wire major_out = major_buf[0] & major_buf[1] |
                 major_buf[0] & major_buf[2] |
                 major_buf[1] & major_buf[2]; 
                 
reg stopBitIsGood;

// Стартовая инициализация автомата
initial 
begin
	state = RESET; // Установка автомата в состояние сброса
	baud_flag = 0;
	baud_counter = 0;
	bit_counter = 0;
	UART_RX_Data_Out = 0;
	UART_RX_Ready_Out = 0;
	major_buf = -1;
	stopBitIsGood = 0;
end

always@(posedge clk)
    major_buf <= {major_buf[1:0], rx};

// Блок обработки текущего состояния
always@(posedge clk)
begin
	case(state)
	   RESET: // Сброс автомата
			begin
				bit_counter <= 0; 	
				baud_counter <= 0;
				stopBitIsGood <= 0;
				UART_RX_Data_Out <= 0;
		        UART_RX_Ready_Out <= 0;
				state <= WAIT_START_BIT;
			end

					
		WAIT_START_BIT: // Состояние ожидания прихода стартового бита (стартовый бит всегда равен нулю)
			// Если пришёл стартовый бит (равный 0),
			// автомат выходит из простоя и начинает работу с пакетом 
			if (~major_out)
                state <= LOAD_BIT;
				
		LOAD_BIT: // Состояние загрузки очередного бита
			// Считывание очередного бита производится только в середине
			// такта BAUD_RATE для повышения надёжности передачи данных
			if (baud_flag)
				// Ожидаем прихода стоп-бита
			    if (bit_counter == 10)
			    begin
			            // Если пришёл стоп-бит (равный 1)
						if (major_out && stopBitIsGood)
							UART_RX_Ready_Out <= 1; // Ставим в 1-цу флаг о том, что пакет принят
							
						// Если стоп-бит не пришёл, также уходим в сброс, однако флаг сигнализирует, 
						// что пакет не был принят, т.е. входные данные этого пакета игнорируются
						state <= RESET;
				end
				else if (bit_counter == 9)
					begin
						stopBitIsGood <= major_out;
					    bit_counter <= bit_counter + 1;
					end
				// Ожидаем очередной бит (не стоп-бит)
				else
				    begin 
					    if (bit_counter != 0) // бит по счёту - не стартовый (данный бит не несёт информацию, а лишь ограничивает пакет)
                            UART_RX_Data_Out <= {major_out, UART_RX_Data_Out[7:1]};
					    
					    bit_counter <= bit_counter + 1; // счётчик битов увеличивается на 1-цу
						state <= WAIT_HALF_RATE;			
					end	
					
		WAIT_HALF_RATE: // Производится простой автомата до конца такта BAUD_RATE
			// Когда прождали, переходим к загрузке следующего бита
			if (baud_flag)
				state <= LOAD_BIT;
	endcase
	
	// Когда дошли до границы BAUD_RATE
	if (baud_counter == CLOCK_RATE / BAUD_RATE / 2)
		begin
			baud_flag <= 1;     // Установка значения флага в единицу
			baud_counter <= 0;  // Сбрасываем счётчик в ноль
		end
	// Иначе
	else 
		begin
			baud_flag <= 0;		// Установка значения флага в ноль
			baud_counter <= baud_counter + 1; // Продолжаем подсчёт
		end
end 
endmodule

