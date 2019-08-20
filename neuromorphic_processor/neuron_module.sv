`timescale 1ns / 1ps
module neuron_module #(parameter ACTIVITY_LEN = 9, REFRACTORY_LEN = 4, REFRACTORY_PER = 4, NEURON_NO = 256)
	(input logic clk, reset,
	 input logic sys_en,
	 input logic [1:0] ext_req,
	 input logic [$clog2(NEURON_NO)-1:0] ext_rd_addr, ext_wr_addr,
	 input logic [NEURON_LEN-1:0] ext_neur_data_in,
	 output logic spike,
	 output logic [TD_WIDTH+$clog2(NEURON_NO)-1:0] spiking_neur_addr);

localparam NEURON_LEN = ACTIVITY_LEN + REFRACTORY_LEN;
localparam DT = 100000;										// 1 ms/ 10 ns
localparam TD_WIDTH = 16;							

logic [NEURON_LEN-1:0] neuron_ram [NEURON_NO-1:0];			// main memory
logic int_rd_en, ext_rd_en, rd_en;							// read enable signals
logic int_wr_en, ext_wr_tmp1, ext_wr_tmp2, ext_wr_en;		// write enable signals
logic wr_en_tmp1, wr_en_tmp2, wr_en;  		
logic scroll_on, ext_access;

logic [$clog2(NEURON_NO)-1:0] rd_addr, wr_addr; 			//
logic [$clog2(NEURON_NO)-1:0] int_rd_addr;					//
logic [$clog2(NEURON_NO)-1:0] wr_addr_tmp1, wr_addr_tmp2;	//

logic [NEURON_LEN-1:0] scroll_data_in, scroll_data_out;		// scrolling data result

logic [$clog2(DT)-1:0] dt_count;							// counting clks until dt (1ms)
logic dt_tick;								 				// generate tick every 1ms
logic [TD_WIDTH-1:0] time_stamp;							// time stamping


		// dT counter 
always @(posedge clk)		
	if (reset) dt_count <= 2**$clog2(DT)-1;				
	else if (sys_en) dt_count <= (dt_count < DT) ? dt_count + 1'b1 : 0;

		// dt tick which is activated every 1 ms
assign dt_tick = (reset) ? 0 : ((dt_count == 2**$clog2(DT)-1) | (dt_count == DT));

// --------------------------------------------------------------------------
// Reading
// --------------------------------------------------------------------------
	// Internal signals
assign int_rd_en = (reset) ? 0 : (0 < dt_count & dt_count < NEURON_NO + 1);
assign int_wr_en = (reset) ? 0 : (3 < dt_count & dt_count < NEURON_NO + 4);
assign scroll_on = int_rd_en | int_wr_en;		
	// External signals
assign ext_access = (ext_req != 2'b00) & ~scroll_on;

	// Enable external signals: enable read at external request is 1, and write at external request is 2								
assign ext_rd_en = ext_access ? (ext_req > 0 ? 1 : 0) : 0;		
assign ext_wr_en = ext_access ? (ext_req > 1 ? 1 : 0) : 0;	
assign rd_en = int_rd_en | ext_rd_en;

	// Read address: internal and external read address
always @(posedge clk)										
	if (reset) int_rd_addr <= 0;									
	else if (int_rd_en) int_rd_addr <= (dt_tick) ? 0 : int_rd_addr + 1'b1;
assign rd_addr = ext_rd_en ? ext_rd_addr : int_rd_addr; 	

	// Reading: internal and external reading
always @(posedge clk)		
	if (reset) scroll_data_in <= 0;								
	else if (rd_en) scroll_data_in <= neuron_ram[rd_addr];		
	else if (dt_count > NEURON_NO & ext_req == 2'b00) scroll_data_in <= 0;

	// Spike generation using Poisson spike generation module
spike_poisson #(.ACTIVITY_LEN(ACTIVITY_LEN), .REFRACTORY_LEN(REFRACTORY_LEN), .REFRACTORY_PER(REFRACTORY_PER)) spike_module (
	.clk(clk),
	.reset(reset),
	.poisson_en(sys_en),
	.poisson_in(scroll_data_in),
	.poisson_out(scroll_data_out),
	.spike(spike));

// --------------------------------------------------------------------------
// Writing 
// --------------------------------------------------------------------------
	// Write enable: internal and external write enable signals 
	// note: this signal does not activated when direct external write signal is inserted
always @(posedge clk) begin
	wr_en_tmp1 	<= rd_en;
	wr_en_tmp2 	<= wr_en_tmp1;
	wr_en		<= wr_en_tmp2;
end

	// Write address: internal and external write addresses
	// note: this signal does not activated when direct external write signal is inserted	
always @(posedge clk) begin
	wr_addr_tmp1 <= rd_addr;
	wr_addr_tmp2 <= wr_addr_tmp1;
	wr_addr		 <= wr_addr_tmp2;
end
	
	// Writing: internal and external writing
always @(posedge clk)
	if (wr_en) neuron_ram[wr_addr] <= scroll_data_out;
	else if (ext_wr_en) neuron_ram[ext_wr_addr] <= ext_neur_data_in;

	// time stamping spiking information
always @(posedge clk)
	if (reset) time_stamp <= 0;
	else if (sys_en & dt_tick) time_stamp <= time_stamp + 1'b1;

always @(posedge clk)
	if (reset) spiking_neur_addr <= 0;
	else if (spike) spiking_neur_addr <= {time_stamp, wr_addr + 1'b1};

initial begin
	for (int i=0; i<NEURON_NO; i++) begin
		if (i==0) neuron_ram[i] = 13'h1ee4;
		else if (i==10) neuron_ram[i] = 13'h1111;
		else if (i==NEURON_NO-1) neuron_ram[i] = 13'h1ff4;
		else neuron_ram[i] = 0;
	end
	dt_count = 0;
	time_stamp = 0;
end
endmodule
