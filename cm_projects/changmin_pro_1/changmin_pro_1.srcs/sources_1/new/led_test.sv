`timescale 1ns / 1ps
module led_test
	(input logic usrclk_p, usrclk_n,
	 input logic reset,
	 output logic [7:0] led);

localparam CYC_NO = 10000000; 					// 1ns / 

logic [$clog2(CYC_NO)-1:0] count;					// Maximum size of count
logic count_end_flag;
logic [7:0] led_reg;

clk_wiz_0 clk_module(
	.clk_in1_p(usrclk_p),
	.clk_in1_n(usrclk_n),
	.clk_out1(clk));

assign count_end_flag = (count == CYC_NO);

always @(posedge clk) 	// at every positive clock
	if (reset) count <= 0; 
	else if (~count_end_flag) count <= count + 1; 
	else if (count_end_flag) count <= 0;

always @(posedge clk)
	if (reset) led_reg <= 0;
	else if (count_end_flag) led_reg <= ~led_reg;

assign led = led_reg;

initial begin
	count = 0;
	led_reg = '0;
end
endmodule
