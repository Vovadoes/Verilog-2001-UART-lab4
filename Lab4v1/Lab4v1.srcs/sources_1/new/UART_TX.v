module UART_TX # 
(
	parameter CLOCK_RATE = 100_000_000, // Частота ПЛИС - по умолчанию, частота XC7A100T-1CSG324C семейства Artix-7 (в Гц)
	parameter BAUD_RATE = 9600			// Скорость передачи данных по UART (в бод)
)
(
	input clk, 				// Синхросигнал
	input [7:0] UART_TX_Data_In, 	// Данные (пакет) для передачи по UART 
	input UART_TX_Ready_In, 	// Сигнал о готовности данных на входе
	output reg tx,                 // бит на выход (Transmit)
	output reg idle	               // сигнал о том, что автомат готов принять новые данные и осуществить их отправку
);
reg [7:0] data_buf;
reg [$clog2(CLOCK_RATE / BAUD_RATE):0] baud_counter; // Cчётчик частоты передачи UART
reg [3:0] bit_counter; 	// счётчик переданных бит
wire baud_flag;	// Флаг о том, что счётчик синхросигнала стал равен половине такта BAUD_RATE 
assign baud_flag = baud_counter == CLOCK_RATE / BAUD_RATE;
reg [1:0] state; // регистр текущего состояния автомата
localparam RESET = 0, WAIT_READY_IN = 1, SEND_DATA = 2;

// Стартовая инициализация автомата
initial 
begin
	state = RESET; // Установка начального состояния автомата в состояния сброса
	tx <= 1; 
	data_buf <= 0;
	baud_counter <= 0;
	bit_counter <= 0;
	idle <= 1;	
end

always@ (posedge clk)
begin
	case(state)
		RESET: // Сброс
			begin
				bit_counter <= 0;
				baud_counter <= 0;
				tx <= 1;
				
				idle <= 1;
				state <= WAIT_READY_IN;
			end
			
		WAIT_READY_IN: // Ожидание прихода очередного пакета данных
            if (UART_TX_Ready_In) 
                begin
					idle <= 0;
                    data_buf <= UART_TX_Data_In;
                    tx <= 0;
                    state <= SEND_DATA;
                end
		SEND_DATA: // Отправка очередного бита по UART в нужный момент времени
            if (baud_flag) 
                begin
                    if (bit_counter == 8)
                        tx <= 1;
                    else if (bit_counter == 9)    
                        begin
                        end
                    else if (bit_counter == 10)    
                        state <= RESET;     
                    else
                        tx <= data_buf[bit_counter];
                    bit_counter <= bit_counter + 1;
                    baud_counter <= 0;
                end
            else
                baud_counter <= baud_counter + 1;    
	endcase
end
endmodule
