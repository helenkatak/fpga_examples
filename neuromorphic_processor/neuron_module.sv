`timescale 1ns / 1ps
module neuron_module #(parameter NEURON_NO=256, ACTIVITY_LEN=9, REFRACTORY_LEN=4, TD_WIDTH=16, REFRACTORY_PER=4)
	(input logic clk, reset, sys_en,
	 input logic [1:0] ext_req,
	 input logic [$clog2(NEURON_NO)-1:0] ext_rd_addr, ext_wr_addr,
	 input logic [NEURON_LEN-1:0] ext_neur_data_in, 
	 output logic [NEURON_LEN-1:0] ext_neur_data_out,
	 output logic [TD_WIDTH+$clog2(NEURON_NO)-1:0] spiking_neur_addr,
	 output logic spike);

localparam NEURON_LEN = ACTIVITY_LEN + REFRACTORY_LEN;
localparam DT = 100000;																// 1 ms/ 10 ns					

logic [NEURON_LEN-1:0] neuron_ram [NEURON_NO-1:0];									// Neuron memory
logic [NEURON_LEN-1:0] data_out_reg;	
logic [$clog2(DT)-1:0] dt_count;													// Counts clock
logic dt_tick;								 										// Generates tick every 1ms
logic [TD_WIDTH-1:0] time_stamp;													// Time stamp
logic int_rd_en, int_wr_en, scroll_on; 												// Internal enable signals
logic [$clog2(NEURON_NO)-1:0] int_rd_addr, int_wr_addr, wr_addr_tmp1, wr_addr_tmp2;	// Internal read and write addresses
logic [NEURON_LEN-1:0] scroll_data_in, scroll_data_out;								// Internal input and output data 
logic [TD_WIDTH+$clog2(NEURON_NO)-1:0] int_neur_data_out;						

// ------------------------ Internal process --------------------------------
	// dT counter activates dt_tick every 1 ms
always @(posedge clk)							
	if (reset) dt_count <= '0;				
	else if (sys_en) dt_count <= (dt_count < DT) ? dt_count + 1'b1 : ((ext_req > 0) ? dt_count : 0);
assign dt_tick = (dt_count == DT);

	// Internal signals
assign int_rd_en = (reset) ? '0 : (0 < dt_count & dt_count < NEURON_NO + 1);
assign int_wr_en = (reset) ? '0 : (3 < dt_count & dt_count < NEURON_NO + 4);
assign scroll_on = (int_rd_en | int_wr_en) & (ext_req > 0);		

	// Internal read address
always @(posedge clk)													
	if (reset) int_rd_addr <= '0;									
	else if (int_rd_en) int_rd_addr <= (dt_tick) ? 0 : ((ext_req > 0) ? int_rd_addr :int_rd_addr + 1'b1);

	// Internal read	
always @(posedge clk)		
	if (reset) scroll_data_in <= '0;						
	else if (int_rd_en) scroll_data_in <= neuron_ram[int_rd_addr];		
	else if (dt_count > NEURON_NO) scroll_data_in <= 0;

	// Spike generation using Poisson spike generation module
spike_poisson #(								
	.ACTIVITY_LEN(ACTIVITY_LEN), 
	.REFRACTORY_LEN(REFRACTORY_LEN), 
	.REFRACTORY_PER(REFRACTORY_PER)) 
	spike_module (
	.clk(clk),
	.reset(reset),
	.poisson_en(sys_en&ext_req==0),
	.poisson_in(scroll_data_in),
	.poisson_out(scroll_data_out),
	.spike_out(spike));

	// Internal write address
always @(posedge clk) begin
	wr_addr_tmp1 <= int_rd_addr;
	wr_addr_tmp2 <= wr_addr_tmp1;
	int_wr_addr	 <= wr_addr_tmp2;
end

// ----------------------- External and Internal write ----------------------
always @(posedge clk)
	if (ext_req == 2) neuron_ram[ext_wr_addr] <= ext_neur_data_in;
	else if (int_wr_en) neuron_ram[int_wr_addr] <= scroll_data_out;

// ------------------------ External process --------------------------------
	//  External read (External signals: "ext_req = 1" enables read signal, and "ext_req = 2" enables write signal)	
always @(posedge clk)
	if (reset) data_out_reg <= '0;
	else if (ext_req == 1) data_out_reg <= neuron_ram[ext_rd_addr];
assign ext_neur_data_out = data_out_reg;

	// time stamping spiking information
always @(posedge clk)
	if (reset) time_stamp <= '0;
	else if (sys_en & dt_tick) time_stamp <= time_stamp + 1'b1;

always @(posedge clk)
	if (reset) int_neur_data_out <= '0;
	else if (spike) begin
		if (int_wr_addr==3'b00) int_neur_data_out <= {time_stamp, int_wr_addr};
		if (int_wr_addr!=3'b00) int_neur_data_out <= {time_stamp, int_wr_addr+3'b01};
	end
	else int_neur_data_out <= '0;
assign spiking_neur_addr = int_neur_data_out;

initial begin
	for (int i=0; i<NEURON_NO; i++) begin
		if (i==0) neuron_ram[i] = 13'h1FF3;					// 1ff = 512 Hz
		else if (i==NEURON_NO/2) neuron_ram[i] = 13'hc83;	// c8 = 200 Hz
		else if (i==NEURON_NO-1) neuron_ram[i] = 13'h644;	// 6 = ?? Hz
		else neuron_ram[i] = 0;
	end
	dt_count = '0;
	time_stamp = '0;
	data_out_reg = '0;
	int_neur_data_out = '0;
	int_rd_addr = '0;
	int_wr_addr = '0;
	wr_addr_tmp1 = '0;
	wr_addr_tmp2 = '0;
	scroll_data_in = '0;
end
endmodule
