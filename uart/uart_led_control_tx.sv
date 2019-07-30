`timescale 1ns / 1ps
module uart_led_control_tx
	(input logic clk, 
	 output logic tx_data_out);

logic [7:0] sw_state;
logic tx_ready;
logic tx_serial, tx_active;

uart_tx #(.CLKS_PER_BIT(868)) uart_tx(
	.i_Clock(clk),
	.i_Tx_DV(tx_ready),
	.i_Tx_Byte(tx_data_in),
	.o_Tx_Active(tx_active),
	.o_Tx_Serial(tx_serial),
 	.o_Tx_Done(tx_data_out));

assign tx_data_in[7:0] = sw_state[7:0];

always @(posedge clk)
	if (tx_ready) tx_data_out <= int(tx_data_in[7:0]);


endmodule
