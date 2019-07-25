`timescale 1ns / 1ps
module uart
	(input logic 	usrclk_n, usrclk_p,
	 input logic 	rx_data_in,
	 output logic 	[7:0] led);

logic clk;
logic rx_sync;
logic rx_temp;
logic [7:0] data_reg;
logic [2:0] data_reg_bit;
logic [2:0] rx_data_out;
logic rx_ready;
logic led_ready;

clk_wiz_0 clk_module(
	.clk_in1_n(usrclk_n),
	.clk_in1_p(usrclk_p),
	.clk_out1(clk));

uart_rx #(.CLKS_PER_BIT(87)) uart_rx (
	.i_Clock(clk),
	.i_Rx_Serial(rx_sync),
	.o_Rx_DV(rx_ready),
	.o_Rx_Byte(rx_data_out));

// syncronizer
always @(posedge clk)
	begin
		rx_temp <= rx_data_in; 				
		rx_sync <= rx_temp;
	end

always @(posedge clk)
	if (rx_ready) data_reg_bit <= rx_data_out;

always @(posedge clk)
	led_ready <= rx_ready;

always @(posedge clk) 
	if (led_ready) data_reg[data_reg_bit] <= ~data_reg[data_reg_bit];

assign led = data_reg;

initial begin
	data_reg = 0;
	data_reg_bit = 0;
	rx_sync = 0;
	rx_temp = 0;
	led_ready = 0;
end	
endmodule