`timescale 1ns / 1ps
module main_module
	(input logic 	usrclk_p, usrclk_n, 
 	 input logic 	reset,
 	 input logic 	rx_din,									// 1 byte input from PC
	 output logic 	tx_dout,
	 output logic 	[7:0] led);

clk_wiz_0 clock_module(
	.clk_in1_p(usrclk_p),
	.clk_in1_n(usrclk_n),
	.clk_out1(clk));

localparam NEURON_NO = 256;
localparam ACTIVITY_LEN = 9;
localparam REFRACTORY_LEN = 4;
localparam REFRACTORY_PER = 4;
localparam NEURON_LEN = ACTIVITY_LEN + REFRACTORY_LEN;
localparam TD_WIDTH = 16;
localparam FIFO_MEM_NO = 4;
localparam UART_DATA_LEN = 8;
localparam UART_CYC=3;

// Neuron module signals
logic sys_en;
logic [1:0] ext_req;										// External request signal
logic [$clog2(NEURON_NO)-1:0] ext_rd_addr, ext_wr_addr;		// External read and write address of neuron memory
logic [NEURON_LEN-1:0] ext_neur_data_in, ext_neur_data_out;	// Externaly input data into neuron memory
logic spike;												// Write signal for FIFO module
logic [TD_WIDTH+$clog2(NEURON_NO)-1:0] spiking_neur_addr;	// Input data for FIFO module
// FIFO module signals
logic [TD_WIDTH+$clog2(NEURON_NO)-1:0] fifo_dout;			
logic fifo_rd;
											
system_ctrl #(.TD_WIDTH(TD_WIDTH), .NEURON_NO(NEURON_NO), .UART_DATA_LEN(UART_DATA_LEN), .UART_CYC(UART_CYC), .NEURON_LEN(NEURON_LEN)) system_ctrl(							
	.clk(clk),									
	.reset(reset),
	.rx_din(rx_din),
	.led(led),
	.sys_en(sys_en),
	.fifo_rd(fifo_rd),
	.ext_req(ext_req),
	.ext_rd_addr(ext_rd_addr),
	.ext_wr_addr(ext_wr_addr),
	.ext_neur_data_out(ext_neur_data_out),
	.ext_neur_data_in(ext_neur_data_in),
	.spike(spike),
	.fifo_dout(fifo_dout),
	.tx_dout(tx_dout));

neuron_module #(
	.NEURON_NO(NEURON_NO), 
	.ACTIVITY_LEN(ACTIVITY_LEN), 
	.REFRACTORY_LEN(REFRACTORY_LEN), 
	.TD_WIDTH(TD_WIDTH),
	.REFRACTORY_PER(REFRACTORY_PER)) 
	neuron_module (
	.clk(clk),
	.reset(reset),
	.sys_en(sys_en),
	.ext_req(ext_req),
	.ext_rd_addr(ext_rd_addr),
	.ext_wr_addr(ext_wr_addr),
	.ext_neur_data_in(ext_neur_data_in),
	.ext_neur_data_out(ext_neur_data_out),
	.spiking_neur_addr(spiking_neur_addr),
	.spike(spike));

fifo #(.FIFO_MEM_LEN(TD_WIDTH+$clog2(NEURON_NO)), .FIFO_MEM_NO(FIFO_MEM_NO)) fifo_module (
	.clk(clk),
	.reset(reset),
	.sys_en(sys_en),
	.rd(fifo_rd), 							// Reading happens when it is required
	.wr(spike),								// Writing happens when system is enabled
	.fifo_din(spiking_neur_addr),
	.fifo_dout(fifo_dout));

endmodule
