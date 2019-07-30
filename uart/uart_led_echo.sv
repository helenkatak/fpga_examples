`timescale 1ns / 1ps
module uart_led_echo
	(input logic  usrclk_n, usrclk_p,
	 input logic rx_data_in,
	 output logic tx_data_out);

// uart rx signals
logic clk;
logic [7:0] data_reg;
logic rx_ready;							// rx ready signal
logic rx_temp, rx_sync;					// temprary and synchronized rxs
logic [7:0] rx_data_out;				// output data from uart
// uart tx signals
logic [7:0] tx_data_in;
logic tx_ready;
logic echoed_value;

logic tx_active, tx_done;
// clocking module
clk_wiz_0 clk_module(
	.clk_in1_n(usrclk_n),
	.clk_in1_p(usrclk_p),
	.clk_out1(clk));
// uart rx module
uart_rx #(.CLKS_PER_BIT(87)) uart_rx ( 
	.i_Clock(clk),
	.i_Rx_Serial(rx_sync),
	.o_Rx_DV(rx_ready),
	.o_Rx_Byte(rx_data_out));
// uart tx_module
uart_tx #(.CLKS_PER_BIT(87)) uart_tx (
	.i_Clock(clk),
	.i_Tx_DV(tx_ready),
	.i_Tx_Byte(tx_data_in),
	.o_Tx_Active(tx_active),
	.o_Tx_Serial(tx_data_out),
	.o_Tx_Done(tx_done));

// syncronizer
always @(posedge clk)
	begin
		rx_temp <= rx_data_in; 				
		rx_sync <= rx_temp;
	end

always @(posedge clk)
	if (rx_ready) data_reg <= rx_data_out;

always @(posedge clk)
	tx_ready <= rx_ready;

assign tx_data_in = data_reg;	
	
endmodule
