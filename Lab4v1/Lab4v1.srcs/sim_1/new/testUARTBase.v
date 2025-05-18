`timescale 1ns / 1ps


module testUARTBase(

    );
    
localparam CLOCK_RATE = 100_000_000; // Частота ПЛИС - по умолчанию, частота XC7A100T-1CSG324C семейства Artix-7 (в Гц)
localparam BAUD_RATE = 9600;			// Скорость передачи данных по UART (в бод)

localparam LENGHT_ARR = 4;

reg clk;
always #(10) clk <= ~clk;

wire RsRx;
wire RsTx;

reg [7:0] UART_TX_Data_In;
reg UART_TX_Ready_In;
wire tx;
wire idle;

reg [7:0] UART_TX_Data_Arr [0:LENGHT_ARR - 1];

reg [0:2] state;

assign RsRx = tx;

initial
begin
    clk = 0;
    state = 0;
    UART_TX_Data_In = 0;
    UART_TX_Ready_In = 0;
    
    UART_TX_Data_Arr[0] = 8'h41;
    UART_TX_Data_Arr[1] = 8'h42;
    UART_TX_Data_Arr[2] = 8'h43;
    UART_TX_Data_Arr[3] = 8'h44;
end

always@ (posedge clk)
begin
    case(state)
        (0): 
        begin
            if (idle)
            begin
                UART_TX_Data_In <= 8'h41;
                UART_TX_Ready_In <= 1;
                state <= 1;
            end
        end
        
        
        (1): 
        begin
            UART_TX_Ready_In <= 0;
            state <= 2;
        end
        
        (2): 
        begin
            if (idle)
            begin
                UART_TX_Data_In <= 8'h0D;
                UART_TX_Ready_In <= 1;
                state <= 3;
            end
        end
        
        
        (3): 
        begin
            UART_TX_Ready_In <= 0;
            state <= 4;
        end
        
        (4):
        begin
            
        end
        
    endcase
end


UART_TX uartTx1(
    .clk(clk),
    .UART_TX_Data_In(UART_TX_Data_In),
    .UART_TX_Ready_In(UART_TX_Ready_In),
    .tx(tx),
    .idle(idle)
);

UART uart1(
    .clk(clk),
    .RsRx(RsRx),
    .RsTx(RsTx)
);

endmodule
