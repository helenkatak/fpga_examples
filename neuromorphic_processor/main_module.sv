`timescale 1ns / 1ps
module main_module
	(input logic usrclk_p, usrclk_n, 
 	 input logic reset
	 );

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
localparam FIFO_MEM_NO = 3;
localparam UART_DATA_LEN = 8;

// Neuron module signals
logic sys_en;
logic ext_req;													// External request signal
logic [$clog2(NEURON_NO)-1:0] ext_rd_addr, ext_wr_addr;			// External read and write address of neuron memory
logic [NEURON_LEN-1:0] ext_neur_data_in, ext_neur_data_out;		// Externaly input data into neuron memory
logic spike;													// Write signal for FIFO module
logic [TD_WIDTH+$clog2(NEURON_NO)-1:0] spiking_neur_addr;		// Input data for FIFO module
// FIFO module signals
logic [TD_WIDTH+$clog2(NEURON_NO)-1:0] fifo_data_out;			
logic fifo_rd, fifo_wr;
// Chunked data module signals
logic out_val;													// High when data is chunked
logic [UART_DATA_LEN-1:0] chunked_data;							// 3X8bit data

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

assign fifo_wr = spike;

fifo #(.FIFO_MEM_LEN(TD_WIDTH+$clog2(NEURON_NO)), .FIFO_MEM_NO(FIFO_MEM_NO)) fifo_module (
	.clk(clk),
	.reset(reset),
	.rd(fifo_rd), 
	.wr(fifo_wr),
	.fifo_data_in(spiking_neur_addr),
	.fifo_data_out(fifo_data_out),
	.empty(fifo_empty), 
	.full(fifo_full));

data_chunking #(.INPUT_LEN(TD_WIDTH+$clog2(NEURON_NO)), .OUTPUT_LEN(UART_DATA_LEN)) data_chunk_module (
	.clk(clk),
	.reset(reset),
	.data_in(fifo_data_out),
	.out_val(out_val),
	.data_out(chunked_data));

initial begin
	sys_en = 0;
	ext_req = 0;
	ext_rd_addr = 0;
	ext_wr_addr = 0;
	ext_neur_data_in = 0;
	fifo_rd = 0;
end
endmodule
