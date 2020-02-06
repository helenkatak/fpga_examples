`timescale 1ns / 1ps
module neuron_module #(parameter NEURON_NO=2**8, ACTIVITY_LEN=9, REFRACTORY_LEN=4, TS_WIDTH=16, REFRACTORY_PER=4)
	(input logic 	clk, reset, sys_en,
	 input logic 	[1:0] ext_req,
	 input logic 	[$clog2(NEURON_NO)-1:0] ext_rd_addr, ext_wr_addr,
	 input logic 	[NEURON_LEN-1:0] ext_din, 
	 output logic 	[NEURON_LEN-1:0] ext_dout,
	 output logic 	[TS_WIDTH+$clog2(NEURON_NO)-1:0] spike_addr,
	 output logic 	spike);

localparam NEURON_LEN = ACTIVITY_LEN + REFRACTORY_LEN;
localparam DT = 1000;																// 1 ms/ 10 ns					

logic [NEURON_LEN-1:0] neuron_ram [NEURON_NO-1:0];									// Neuron memory
logic [NEURON_LEN-1:0] dout_reg;	

struct {logic [$clog2(DT)-1:0] count;			// Counts clock
		logic en, tick;	
		logic [TS_WIDTH-1:0] ts;				// Time stamp
		} dt;				 					// Generates tick every 1ms
struct {logic en;								// Internal enable signals
		logic [$clog2(NEURON_NO)-1:0] addr;		// Internal read and write addresses
		logic [TS_WIDTH+$clog2(NEURON_NO)-1:0] dout;	
		logic [NEURON_LEN-1:0] dreg; 			// Internal input and output data 
		} int_rd;					
struct {logic en, en_tmp1, en_tmp2;
		logic [$clog2(NEURON_NO)-1:0] addr, addr_tmp1, addr_tmp2;
		logic [NEURON_LEN-1:0] dreg;
		} int_wr;

// logic scroll_on;
// ------------------------ Internal process --------------------------------
	// dT counter activates dt.tick every 1 ms
assign dt.tick = (dt.count == DT-1);

always @(posedge clk)							
	if (reset) dt.en <= 0;				
	else if (sys_en) dt.en <= 1'b1;
			
always @(posedge clk)
	if (reset) dt.count <= 0;
	else if (dt.en) dt.count <= (dt.tick) ? 0 : dt.count + 1'b1;

	// Internal signal enable 
always @(posedge clk)
	if (reset) int_rd.en <= 0;
	else if (dt.tick) int_rd.en <= (~ext_req) ? 1'b1 : 0;
	else if (~ext_req) int_rd.en <= (int_rd.addr==NEURON_NO-1) ? 0 : int_rd.en; 

always @(posedge clk)
	if (reset) int_rd.addr <= '0;
	else if (ext_req) int_rd.addr <= int_rd.addr;
	else if (~dt.tick)  int_rd.addr <= (int_rd.addr==NEURON_NO-1) ? int_rd.addr : int_rd.addr + 1'b1;
	else int_rd.addr <= int_rd.addr + 1'b1;

	// Internal read
always @(posedge clk)		
	if (reset) int_rd.dreg <= '0;						
	else if (int_rd.en) int_rd.dreg <= neuron_ram[int_rd.addr];		
	else if (dt.count > NEURON_NO-1) int_rd.dreg <= 0;

	// Spike generation using Poisson spike generation module
spike_poisson #(								
	.ACTIVITY_LEN(ACTIVITY_LEN), 
	.REFRACTORY_LEN(REFRACTORY_LEN), 
	.REFRACTORY_PER(REFRACTORY_PER)) 
	spike_module (
	.clk(clk),
	.reset(reset),
	.poisson_en(~ext_req),
	.poisson_in(int_rd.dreg),
	.poisson_out(int_wr.dreg),
	.spike_out(spike));

	// Internal write address
always @(posedge clk) begin
	int_wr.addr_tmp1 <= int_rd.addr;
	int_wr.addr_tmp2 <= int_wr.addr_tmp1;
	int_wr.addr	 	 <= int_wr.addr_tmp2;
	int_wr.en_tmp1 	 <= int_rd.en;
	int_wr.en_tmp2 	 <= int_wr.en_tmp1;
	int_wr.en	 	 <= int_wr.en_tmp2;
end

// ----------------------- External and Internal write ----------------------
always @(posedge clk)
	if (int_wr.en) neuron_ram[int_wr.addr] <= int_wr.dreg;
	else if (ext_req == 2) neuron_ram[ext_wr_addr] <= ext_din;

// ------------------------ External process --------------------------------
	//  External read (External signals: "ext_req = 1" enables read signal, and "ext_req = 2" enables write signal)	
always @(posedge clk)
	if (reset) dout_reg <= '0;
	else if (ext_req == 1) dout_reg <= neuron_ram[ext_rd_addr];
assign ext_dout = dout_reg;

// time stamping spiking information
always @(posedge clk)
	if (reset) dt.ts <= '0;
	else if (dt.tick) dt.ts <= dt.ts + 1'b1;

always @(posedge clk)
	if (reset) int_rd.dout <= '0;
	else if (spike) begin
		if (int_wr.addr==3'b00) int_rd.dout <= {dt.ts, int_wr.addr};
		if (int_wr.addr!=3'b00) int_rd.dout <= {dt.ts, int_wr.addr+3'b01};
	end
	else int_rd.dout <= '0;
assign spike_addr = int_rd.dout;

initial begin
	for (int i=0; i<NEURON_NO; i++) begin
		if (i==0) neuron_ram[i] = 13'hc63;					// 1ff = 512 Hz
		else if (i==NEURON_NO/2) neuron_ram[i] = 13'hc73;	// c8 = 200 Hz
		else if (i==NEURON_NO-1) neuron_ram[i] = 13'hc83;	// 6 = ?? Hz
		else neuron_ram[i] = 0;
	end
	dout_reg = '0;		
	dt.en = 0;
	dt.count = '0;
	dt.ts = '0;
	int_rd.en = 0;
	int_rd.addr = NEURON_NO-1;
	int_rd.dout = '0;
	int_wr.en = 0;
	int_wr.addr = '0;
	int_wr.addr_tmp1 = '0;
	int_wr.addr_tmp2 = '0;
	int_wr.en_tmp1 = 0;
	int_wr.en_tmp2 = 0;
	int_rd.dreg = '0;
	int_wr.dreg = '0;
end
endmodule
