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
localparam TS_WID = 20;
localparam FIFO_MEM_NO = 8;
localparam UART_DATA_LEN = 8;
localparam UART_CYC=3;
localparam OUT_W = 8;

logic sys_en, clk;

clk_wiz_0 clock_module(
	.clk_in1_p(usrclk_p),
	.clk_in1_n(usrclk_n),
	.clk_out1(clk));

struct {logic [UART_DATA_LEN-1:0] data;
		logic dv;
		} rx;

struct {logic dv; 
		logic active;
		logic done;
		} tx;

struct {logic [1:0] req;								// External request signal
		logic [$clog2(NEURON_NO)-1:0] rd_addr, wr_addr;	// External read and write address of neuron memory
		logic [NEURON_LEN-1:0] din, dout;				// Externaly input data into neuron memory
		} ext;

struct {logic signal;										// Write signal for FIFO module	
		logic [TS_WID+$clog2(NEURON_NO)-1:0] addr;	// Input data for FIFO module
		} spike;

struct {logic [TS_WID+$clog2(NEURON_NO)-1:0] dout;		
		logic full, empty, ext_rd;
		} fifo;

logic ser_rdy;
logic [OUT_W-1:0] serialized_data;

uart_rx #(.CLKS_PER_BIT(87)) uart_rx(	// Note: If there is a weak blinking issue, check clk/bits 
	.i_Clock(clk),
	.i_Rx_Serial(rx_din),				// serial input from PC
	.o_Rx_Byte(rx.data),				// 1 byte data recieved
	.o_Rx_DV(rx.dv));					// tells when the entire 1 byte is recieved

system_ctrl #(.TS_WID(TS_WID), .NEURON_NO(NEURON_NO), 
			  .UART_DATA_LEN(UART_DATA_LEN), .UART_CYC(UART_CYC), 
			  .NEURON_LEN(NEURON_LEN)) system_ctrl(							
	.clk(clk),									
	.reset(reset),
	.rx_dv(rx.dv),
	.rx_data(rx.data),
	.sys_en(sys_en),
	.fifo_rd(fifo.ext_rd),
	.ext_req(ext.req),
	.ext_rd_addr(ext.rd_addr),
	.ext_wr_addr(ext.wr_addr),
	.ext_dout(ext.dout),
	.ext_din(ext.din),
	.spike(spike.signal),
	.fifo_dout(fifo.dout));

neuron_module #(.NEURON_NO(NEURON_NO), .TS_WID(TS_WID)) neuron_module (
	.clk(clk),
	.reset(reset),
	.sys_en(sys_en),
	.ext_req(ext.req),
	// .ext_rd_addr(ext.rd_addr),
	// .ext_wr_addr(ext.wr_addr),
	// .ext_din(ext.din),
	// .ext_dout(ext.dout),
	.ts_sp_addr(spike.addr),
	.sp_out(spike.signal));

fifo #(.FIFO_MEM_LEN(TS_WID+$clog2(NEURON_NO)), .FIFO_MEM_NO(FIFO_MEM_NO)) fifo_module (
	.clk(clk),
	.reset(reset),
	.fifo_rd_en(ser_rdy), //fifo.ext_rd), 		// Reading happens when it is required
	.spike(spike.signal),						// Writing happens when system is enabled
	.full(fifo.full),
	.empty(fifo.empty),
	.fifo_din(spike.addr),
	.fifo_dout(fifo.dout));


serializer #(.IN_W(TS_WID+$clog2(NEURON_NO)), .OUT_W(8)) output_ser (
	.clk(clk),
	.reset(reset),
	.fifo_empty(fifo.empty),
	.tx_done(tx.done),
	.tx_dv(tx.dv),
	.data_in(fifo.dout),
	.ser_rdy(ser_rdy),
	.data_out(serialized_data));

uart_tx #(.CLKS_PER_BIT(87)) uart_tx(
	.i_Clock(clk),						
	.i_Tx_DV(tx.dv),					// Start signal sending data to PC
	.i_Tx_Byte(serialized_data),		// 8 bit data to send
	.o_Tx_Active(tx.active),				
	.o_Tx_Serial(tx_dout),				// PC recieves 1 byte data
	.o_Tx_Done(tx.done));				// reduce tx.done signal into half clks

endmodule
