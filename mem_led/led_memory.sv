`timescale 1ns / 1ps
module led_memory
	(input logic usrclk_n, usrclk_p, 	
	 input logic up_btn, down_btn, left_btn, right_btn, change_btn, 
	 output logic [MEM_WIDTH-1:0] led); 	// 4bit led

logic clk, up, down, left, right, change;		// clk and buttons
logic re;	
localparam MEM_HEIGHT = 16;					// memory height
localparam MEM_WIDTH = 7;					// memory bit
logic [MEM_WIDTH-1:0] mem [MEM_HEIGHT-1:0]; // 8 x 4bit memory array
logic [MEM_WIDTH-1:0] data_reg; 	 		// data point in registor 3+1 bit
logic [$clog2(MEM_HEIGHT)-1:0] mem_addr;	// memory address 2^3 = 8
logic [$clog2(MEM_WIDTH)-1:0] data_ptr;		// pointer in data_reg 2^2 = 4

// clocking wizard
clk_wiz_0 clk_module(						
	.clk_in1_n(usrclk_n),
	.clk_in1_p(usrclk_p),
	.clk_out1(clk));

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

always @(posedge clk) 						// write data_reg value to current mem_addr of mem	
	if (up|down) mem[mem_addr] <= data_reg;						

always @(posedge clk)						// update mem_addr if "up" or "down"
	if (up|down) mem_addr <= up ? mem_addr + 1'b1 : mem_addr - 1'b1;	

always @(posedge clk)						// create read enable for a delay 
	re <= (up|down);	
			
always @(posedge clk)
	if (re) data_reg <= mem[mem_addr];		// read mem of updated mem_addr to data_reg
	else if (change) data_reg[data_ptr] <= ~data_reg[data_ptr]; // flip data_reg bit if "change"
		
always @(posedge clk) 						// change pointer of data_reg if "left" or "right"
	if (left|right) data_ptr <= left ? data_ptr - 1'b1 : data_ptr + 1'b1;

assign led = data_reg;						// led is assigned to be data_reg
	
initial begin
	for (int i=0; i<MEM_HEIGHT; i++) begin
		mem[i] = 0;
	end
	mem_addr = 0;
	data_ptr = 0;
	data_reg = 0;	
end

endmodule
