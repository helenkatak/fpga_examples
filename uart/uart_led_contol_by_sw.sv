`timescale 1ns / 1ps
module uart_led_contol_by_sw
	(input logic 	usrclk_n, usrclk_p,
	 input logic 	[7:0] slide_sw,
 	 output logic 	tx_data_out, 
	 output logic 	[7:0] led);

logic clk;
logic sw_tick;
// uart tx signals
logic tx_active, tx_done;
// uart rx signals
logic [7:0] rx_data_out;
logic rx_ready;
// clocking 
clk_wiz_0 clk_module (
	.clk_in1_n(usrclk_n),
	.clk_in1_p(usrclk_p),
	.clk_out1(clk));
// sw detection module
sw_pulse_detect sw_pulse_module (
	.clk(clk),
	.sw_in(slide_sw),
	.sw_pulse(sw_tick));
// uart tx module
uart_tx #(.CLKS_PER_BIT(87)) uart_tx(
	.i_Clock(clk),
	.i_Tx_DV(sw_tick),
	.i_Tx_Byte(slide_sw),
	.o_Tx_Active(tx_active),
	.o_Tx_Serial(tx_data_out),
	.o_Tx_Done(tx_done));
// uart rx module
uart_rx #(.CLKS_PER_BIT(87)) uart_rx(
	.i_Clock(clk),
	.i_Rx_Serial(tx_data_out),
	.o_Rx_Byte(rx_data_out),
	.o_Rx_DV(rx_ready));

assign led = rx_data_out;

// assign tx_data_in = slide_sw;

// always @(posedge clk)
// 	if (sw_tick) tx_data_in <= slide_sw;

endmodule
