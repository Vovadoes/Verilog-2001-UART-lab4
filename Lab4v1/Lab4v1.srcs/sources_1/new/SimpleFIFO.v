`timescale 1ns / 1ps

module SimpleFIFO #(
	MEM_SIZE = 6,	
    DATA_SIZE = 4
)
(
    input reset,
    input clk,
	input enable,
	
    input read_mode,
    input write_mode,
    input [DATA_SIZE-1:0] data_in,
    
    output reg [DATA_SIZE-1:0] data_out,
    output reg full,
    output reg empty,
    output reg valid
);
    
reg [DATA_SIZE-1:0] mem [0:MEM_SIZE-1];				   
reg [$clog2(MEM_SIZE)-1:0] write_pointer, write_pointer_next, write_pointer_succ; 
reg [$clog2(MEM_SIZE)-1:0] read_pointer, read_pointer_next, read_pointer_succ; 
reg full_next, empty_next;

integer i;
initial 
begin
	write_pointer <= 0;
	write_pointer_next <= 0;
	write_pointer_succ <= 0;
	
	read_pointer <= 0;
	read_pointer_next <= 0;
	read_pointer_succ <= 0;
	
	full <= 0;
	full_next <= 0;
	empty <= 1;
	empty_next <= 1;
	
	valid <= 0;
	
	data_out <= 0;
	
	for(i = 0; i < MEM_SIZE; i = i + 1)
		mem[i] <= {DATA_SIZE{1'b0}};
end

// Чтение
always@(posedge clk)
	if (enable && read_mode && !empty)
	begin
		data_out = mem[read_pointer];
		valid <= 1;
    end
    else 
        valid <= 0;
    
// Запись        
always@(posedge clk)
    if (enable && write_mode && !full)        
        mem[write_pointer] <= data_in;

// Сброс/установка следующих значений
always @(posedge clk) begin
    if (reset)
        begin
            write_pointer <= 0;
            read_pointer <= 0;
            full <= 0;    
            empty <= 1'b1;		
        end
    else if (enable)
        begin
            write_pointer <= write_pointer_next;
            read_pointer <= read_pointer_next;
            full <= full_next;
			empty <= empty_next;	
        end
end 
       
// Логика формирования следующих значений
always @*
begin
    write_pointer_succ = (write_pointer + 1) % MEM_SIZE;
    read_pointer_succ = (read_pointer + 1) % MEM_SIZE;
    
    write_pointer_next = write_pointer;
	read_pointer_next = read_pointer;
    full_next = full; 
    empty_next = empty;
    
    case({write_mode, read_mode})
		2'b01: 
            if (!empty)
                begin
                    read_pointer_next = read_pointer_succ;
                    full_next = 0;
                    if (read_pointer_succ == write_pointer)
                        empty_next = 1;
                end       
        2'b10:
            if (!full)
                begin
                    write_pointer_next = write_pointer_succ;
                    empty_next = 0;
                    if (write_pointer_succ == read_pointer)
                        full_next = 1;
                end      
        2'b11:
            begin
            case ({full, empty})
                2'b10:
                    begin
                        read_pointer_next = read_pointer_succ;
                        full_next = 0;
                        if (read_pointer_succ == write_pointer)
                            empty_next = 1;
                    end    
                2'b01:
                    begin
                        write_pointer_next = write_pointer_succ;
                        empty_next = 0;
                        if (write_pointer_succ == read_pointer)
                            full_next = 1;
                    end
                default:
                    begin
                        write_pointer_next = write_pointer_succ;
                        read_pointer_next = read_pointer_succ;
                    end  
            endcase
            end
    endcase
end
endmodule

