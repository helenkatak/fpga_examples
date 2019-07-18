`timescale 1ns / 1ps
module led_memory
	(input logic clk, 	// reset,
	 input up_btn, down_btn, left_btn, right_btn, change_btn, 
	 output logic [7:0] led);

logic re;			// read enable
logic [7:0] mem [15:0];   	// 16 8bit memory 
logic [3:0] mem_addr;		// memory address (2^(3+1))
logic [7:0] data_bit;		// data bit in data_reg
logic [7:0] data_reg; 	 	// data point in registor

// button synchronizers
btn_in up_btn_sync(
	.clk(clk),
	.btn_in(up_btn),
	.btn_out(up));

btn_in down_btn_sync(
	.clk(clk),
	.btn_in(down_btn),
	.btn_out(down));

btn_in left_btn_sync(
	.clk(clk),
	.btn_in(left_btn),
	.btn_out(left));

btn_in right_btn_sync(
	.clk(clk),
	.btn_in(right_btn),
	.btn_out(right));

btn_in change_btn_sync(
	.clk(clk),
	.btn_in(change_btn),
	.btn_out(change));

// UP/DOWN button operation
always @(posedge clk) 	// (1) write data_reg into current memory and update mem_addr	
	if (up|down) 
	begin
		mem[mem_addr] <= data_reg;	
		mem_addr <= up ? mem_addr + 1'b1 : mem_addr - 1'b1;
	end	  	

always @(posedge clk)	// (2) create delay between (1) and (3)
	re <= (up|down);	
			
always @(posedge clk) 	// (3) storing new data to data_reg
	if (re) data_reg <= mem[mem_addr];			

// left/right operation : change bit location of data_reg				
always @(posedge clk) 	
	if (left|right) data_bit <= left ? data_bit + 1'b1 : data_bit - 1'b1;

// CHANGE button operation : flip information from/to 0 to/from 1
always @(posedge clk)
	if (change) data_reg[data_bit] <= ~data_reg[data_bit]; 

assign led = data_reg; 	// send data_reg to operate led 

initial begin
	for (int i=0; i<16; i++) begin
		mem[i] = 0;
	end
	mem_addr = 0;
	data_bit = 0;
	data_reg = 0;	
end

endmodule
