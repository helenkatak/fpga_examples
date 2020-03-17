`timescale 1ns / 1ps
module main_module
	(input logic 	USRCLK_N, USRCLK_P,
 	 input logic 	reset,
 	 // input logic 	rx_din,					// 1 byte input from PC
	 // output logic 	tx_dout,
	 input logic	sys_en,
	 output logic 	[TS_WID+$clog2(NEURON_NO)-1:0] spiking_n_addr,
	 output logic 	sp_out);

localparam NEURON_NO = 256;
localparam TS_WID = 12;
localparam T_FIX_WID = 16;
// localparam FIFO_MEM_NO = 8;
// localparam UART_DATA_LEN = 8;
// localparam UART_CYC=3;
// localparam OUT_W = 8;
localparam DT = 12207;		
localparam W = 40;								// FXnum(0.01, FXfamily(12,1))
localparam CMEM = 5461;							// FXnum(0.04/(0.04-0.01), FXfamily(12,4))
localparam W_CMEM = 54;							// FXnum(0.01*0.04/0.03, FXfamily(12,1))
localparam W_C = 1092;							// FXnum(0.01*0.04/(0.04-0.01)/0.05, FXfamily(12,1))

logic clk;
clk_wiz_0 clock_module(
	.clk_in1_p(USRCLK_P),
	.clk_in1_n(USRCLK_N),
	.clk_out1(clk));

// struct {logic [UART_DATA_LEN-1:0] data;
// 		logic dv;
// 		} rx;

// struct {logic dv; 
// 		logic active;
// 		logic done;
// 		} tx;

logic [1:0] ext_req;								// External request 0: no request 1: ext_rd 2: ext_wr
logic we;
logic [5:0] ram_sel;								// External read and write RAM selection m_s/m_t/s_s/s_t/thr_s/thr_t
logic [T_FIX_WID/2-1:0] ext_rd_addr, ext_wr_addr;	// External read and write address of neuron memory
logic [T_FIX_WID-1:0] ext_din, ext_dout;			// Externaly input data into neuron memory
logic [TS_WID-1:0] dt_ts;
logic [$clog2(DT)-1:0] dt_count;
logic dt_tick;
logic sys_en, en;
logic [$clog2(NEURON_NO)-1:0] n_addr;
logic [TS_WID-1:0] weight_const;
logic sp_out;										// Write signal for FIFO module	
logic [TS_WID+$clog2(NEURON_NO)-1:0] spiking_n_addr;// Input data for FIFO module

logic [NEURON_NO-1:0] spike_in_ram;							
logic input_spike;
assign input_spike = (en) & spike_in_ram[n_addr]; 	// Spike input 

// struct {logic [TS_WID+$clog2(NEURON_NO)-1:0] dout;		
// 		logic full, empty, ext_rd;
// 		} fifo;

// logic ser_rdy;
// logic [OUT_W-1:0] serialized_data;



// uart_rx #(.CLKS_PER_BIT(87)) uart_rx(	// Note: If there is a weak blinking issue, check clk/bits 
// 	.i_Clock(clk),
// 	.i_Rx_Serial(rx_din),					// serial input from PC
// 	.o_Rx_Byte(rx.data),					// 1 byte data recieved
// 	.o_Rx_DV(rx.dv));						// tells when the entire 1 byte is recieved

// system_ctrl #(.TS_WID(TS_WID), .NEURON_NO(NEURON_NO), 
// 			  .UART_DATA_LEN(UART_DATA_LEN), .UART_CYC(UART_CYC), 
// 			  .NEURON_LEN(NEURON_LEN)) system_ctrl(							
// 	.clk(clk),									
// 	.reset(reset),
// 	.rx_dv(rx.dv),
// 	.rx_data(rx.data),
// 	.sys_en(sys_en),
// 	.fifo_rd(fifo.ext_rd),
// 	.ext_req(ext.req),
// 	.ext_rd_addr(ext.rd_addr),
// 	.ext_wr_addr(ext.wr_addr),
// 	.ext_dout(ext.dout),
// 	.ext_din(ext.din),
// 	.spike(spike.signal),
// 	.fifo_dout(fifo.dout));

dt_counter #(.DT(DT), .TS_WID(TS_WID))
	dt_counter_module (
	.clk(clk),
	.reset(reset),
	.sys_en(sys_en),
	.dt_tick(dt_tick),
	.dt_count(dt_count),
	.dt_ts(dt_ts));

int_signal #(.NEURON_NO(NEURON_NO))
	int_singal_module (
	.clk(clk),
	.reset(reset),
	.ext_req(ext_req),
	.dt_tick(dt_tick),
	.en(en),
	.n_addr(n_addr));

neuron_module #(.NEURON_NO(NEURON_NO), .TS_WID(TS_WID)) neuron_module (
	.clk(clk),
	.reset(reset),
	.ext_req(ext_req),
	.ram_sel(ram_sel),
	.ext_rd_addr(ext_rd_addr),
	.ext_wr_addr(ext_wr_addr),
	.ext_din(ext_din),
	.ext_dout(ext_dout),
	.en(en),
	.input_spike(input_spike),
	.weight_const(weight_const),
	.dt_ts(dt_ts),
	.n_addr(n_addr),
	.ts_sp_addr(spiking_n_addr),
	.sp_out(sp_out));

initial begin
	for (int i=0; i<NEURON_NO; i++) begin // spike_in_ram: just for simulation. It need to be replaced
		if (i==0) spike_in_ram[i] = 1;
		else if (i==5) spike_in_ram[i] = 1;
		else if (i==255) spike_in_ram[i] = 1;
		else spike_in_ram[i] = 0;
	end
	ext_req = '0;
	weight_const = 1092;
	ram_sel = '0;
	we = 0;
	sys_en = 1;
	ext_rd_addr = 0;
	ext_wr_addr = 0;
	ext_din = 0;
end

// fifo #(.FIFO_MEM_LEN(TS_WID+$clog2(NEURON_NO)), .FIFO_MEM_NO(FIFO_MEM_NO)) fifo_module (
// 	.clk(clk),
// 	.reset(reset),
// 	.fifo_rd_en(ser_rdy), //fifo.ext_rd), 		// Reading happens when it is required
// 	.spike(spike.signal),						// Writing happens when system is enabled
// 	.full(fifo.full),
// 	.empty(fifo.empty),
// 	.fifo_din(spike.addr),
// 	.fifo_dout(fifo.dout));

// serializer #(.IN_W(TS_WID+$clog2(NEURON_NO)), .OUT_W(8)) output_ser (
// 	.clk(clk),
// 	.reset(reset),
// 	.fifo_empty(fifo.empty),
// 	.tx_done(tx.done),
// 	.tx_dv(tx.dv),
// 	.data_in(fifo.dout),
// 	.ser_rdy(ser_rdy),
// 	.data_out(serialized_data));

// uart_tx #(.CLKS_PER_BIT(87)) uart_tx(
// 	.i_Clock(clk),						
// 	.i_Tx_DV(tx.dv),					// Start signal sending data to PC
// 	.i_Tx_Byte(serialized_data),		// 8 bit data to send
// 	.o_Tx_Active(tx.active),				
// 	.o_Tx_Serial(tx_dout),				// PC recieves 1 byte data
// 	.o_Tx_Done(tx.done));				// reduce tx.done signal into half clks
endmodule
