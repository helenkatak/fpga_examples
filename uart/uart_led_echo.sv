`timescale 1ns / 1ps
module uart_led_echo
	(input logic  usrclk_n, usrclk_p,
	 input logic rx_data_in,
	 output logic tx_data_out);

// uart rx signals
logic clk;								// clock signal from clk_wiz_0
logic [7:0] data_reg;					// data register
logic rx_ready;							// rx ready signal
logic [7:0] rx_data_out;				// output data from uart rx
// uart tx signals
logic tx_ready;							// uart tx input ready signal
logic tx_active;
logic tx_done;							// tx done signal				
// clocking module
clk_wiz_0 clk_module(
	.clk_in1_n(usrclk_n),
	.clk_in1_p(usrclk_p),
	.clk_out1(clk));
// uart rx module
uart_rx #(.CLKS_PER_BIT(87)) uart_rx ( 
	.i_Clock(clk),
	.i_Rx_Serial(rx_data_in),
	.o_Rx_DV(rx_ready),
	.o_Rx_Byte(rx_data_out));
// uart tx_module
uart_tx #(.CLKS_PER_BIT(87)) uart_tx (
	.i_Clock(clk),
	.i_Tx_DV(tx_ready),
	.i_Tx_Byte(data_reg),
	.o_Tx_Active(tx_active),
	.o_Tx_Serial(tx_data_out),
	.o_Tx_Done(tx_done));

always @(posedge clk)					// dalay rx ready output signal to tx ready input signal
 	tx_ready <= rx_ready;	

always @(posedge clk)					// rx output to data register
	if (rx_ready) data_reg <= rx_data_out;	
				
endmodule
