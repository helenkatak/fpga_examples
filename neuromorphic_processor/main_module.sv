`timescale 1ns / 1ps
module main_module
	(input logic 	usrclk_p, usrclk_n, 
 	 input logic 	reset,
 	 input logic 	rx_din,									// 1 byte input from PC
	 output logic 	tx_dout,
	 output logic 	[7:0] led);

localparam NEURON_NO = 256;
localparam ACTIVITY_LEN = 9;
localparam REFRACTORY_LEN = 4;
localparam REFRACTORY_PER = 4;
localparam NEURON_LEN = ACTIVITY_LEN + REFRACTORY_LEN;
localparam TD_WIDTH = 16;
localparam FIFO_MEM_NO = 8;
localparam UART_DATA_LEN = 8;
localparam UART_CYC=3;

logic clk;
clk_wiz_0 clock_module(
	.clk_in1_p(usrclk_p),
	.clk_in1_n(usrclk_n),
	.clk_out1(clk));

logic sys_en;

struct {
logic [1:0] req;								// External request signal
logic [$clog2(NEURON_NO)-1:0] rd_addr, wr_addr;	// External read and write address of neuron memory
logic [NEURON_LEN-1:0] din, dout;				// Externaly input data into neuron memory
} ext;

struct {
logic out;										// Write signal for FIFO module	
logic [TD_WIDTH+$clog2(NEURON_NO)-1:0] addr;	// Input data for FIFO module
} spike;

struct {
logic [TD_WIDTH+$clog2(NEURON_NO)-1:0] dout;		
logic full, empty, ext_rd;
} fifo;
													
system_ctrl #(.TD_WIDTH(TD_WIDTH), .NEURON_NO(NEURON_NO), .UART_DATA_LEN(UART_DATA_LEN), .UART_CYC(UART_CYC), .NEURON_LEN(NEURON_LEN)) system_ctrl(							
	.clk(clk),									
	.reset(reset),
	.rx_ser(rx_din),
	.led(led),
	.sys_en(sys_en),
	.fifo_rd(fifo.ext_rd),
	.ext_req(ext.req),
	.ext_rd_addr(ext.rd_addr),
	.ext_wr_addr(ext.wr_addr),
	.ext_dout(ext.dout),
	.ext_din(ext.din),
	.spike(spike.out),
	.fifo_dout(fifo.dout),
	.tx_dout(tx_dout));

neuron_module #(.NEURON_NO(NEURON_NO), .ACTIVITY_LEN(ACTIVITY_LEN), .REFRACTORY_LEN(REFRACTORY_LEN), .TD_WIDTH(TD_WIDTH),.REFRACTORY_PER(REFRACTORY_PER)) neuron_module (
	.clk(clk),
	.reset(reset),
	.sys_en(sys_en),
	.ext_req(ext.req),
	.ext_rd_addr(ext.rd_addr),
	.ext_wr_addr(ext.wr_addr),
	.ext_din(ext.din),
	.ext_dout(ext.dout),
	.spike_addr(spike.addr),
	.spike(spike.out));

fifo #(.FIFO_MEM_LEN(TD_WIDTH+$clog2(NEURON_NO)), .FIFO_MEM_NO(FIFO_MEM_NO)) fifo_module (
	.clk(clk),
	.reset(reset),
	.fifo_rd_en(fifo.ext_rd), 							// Reading happens when it is required
	.spike(spike.out),						// Writing happens when system is enabled
	.full(fifo.full),
	.empty(fifo.empty),
	.fifo_din(spike.addr),
	.fifo_dout(fifo.dout));
endmodule
