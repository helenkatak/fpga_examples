`timescale 1ns / 1ps
module uart_led_control
	(input logic 	usrclk_n, usrclk_p,
	 input logic 	rx_data_in,
	 output logic 	[7:0] led);

logic clk;
logic [7:0] data_reg;					// data register
logic [7:0] data_reg_ptr;				// data register pointer					
// uart signals 
logic rx_ready;							// rx ready signal
logic rx_temp, rx_sync;					// temprary and synchronized rxs
logic [7:0] rx_data_out;				// output data from uart

// clocking module
clk_wiz_0 clk_module(
	.clk_in1_n(usrclk_n),
	.clk_in1_p(usrclk_p),
	.clk_out1(clk));
// uart module
uart_rx #(.CLKS_PER_BIT(868)) uart_rx (
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

assign data_reg_ptr = rx_data_out;		// assign data register point 

always @(posedge clk)
	if (rx_ready) data_reg[data_reg_ptr[2:0]] <= ~data_reg[data_reg_ptr[2:0]];

assign led = data_reg;

initial begin
	data_reg = 0;
	data_reg_ptr = 0;
	rx_temp = 0;
	rx_sync = 0;
	rx_ready = 0;
end	
endmodule