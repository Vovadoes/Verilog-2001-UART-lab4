`timescale 1ns / 1ps

module fsm #(
    ERROR_COUNT = 2, // Количество ошибок
    DIGIT_COUNT = 4, // Разрядность входных данных, представленных в 16-ричном виде
    localparam ERROR_IN_BIT_SIZE = $clog2(ERROR_COUNT)
)(
    input clk, R_I, reset,
    input [DIGIT_COUNT * 4 - 1 : 0] dataIn,
    output reg R_O,
    output reg [DIGIT_COUNT * 4 - 1 : 0] dataOut,
    output reg [ERROR_IN_BIT_SIZE-1:0] error
    );

    
reg [0:2] state;
reg [DIGIT_COUNT * 4 - 1 : 0] data;
    

initial
begin
    dataOut = 0;
    error = 0;
    state = 0;
    data = 0;
    R_O = 0;
end

always@ (posedge clk)
begin
    case (state)
        (0):
        begin
            if (R_I)
            begin
                data <= dataIn;
                state <= 1;
            end
            else state <= state;
        end
        
        (1):
        begin
            R_O <= 1;
            dataOut <= data;
            state <= 2;
        end
        
        (2):
        begin
            dataOut <= 0;
            error <= 0;
            R_O <= 0;
            state <= 0;
            data <= 0;
        end
        
    endcase

end

endmodule
