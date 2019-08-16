`timescale 1ns / 1ps
module neuron_module #(parameter ACTIVITY_LEN = 9, REFRACTORY_LEN = 4, REFRACTORY_PER = 4, NEURON_NO = 256)
	(input logic clk, reset,
	 input logic sys_en,
	 output logic [NEURON_LEN-1:0] scroll_data_in,
	 output logic spike,
	 output logic [TD_WIDTH+$clog2(NEURON_NO)-1:0] spiking_neur_addr);

localparam NEURON_LEN = ACTIVITY_LEN + REFRACTORY_LEN;
localparam DT = 1000;								// 1 ms/ 10 ns
localparam TD_WIDTH = 16;							

logic [NEURON_LEN-1:0] neuron_ram [NEURON_NO-1:0];	// Main memory
logic rd_en, ext_rd_en, ext_wr_en, wr_en;						// read enable, write enable
logic [$clog2(NEURON_NO)-1:0] rd_addr, wr_addr, wr_temp1, wr_temp2;// reading address, write address
logic [NEURON_LEN-1:0] scroll_data_out;				// scrolling data result
logic [NEURON_LEN-1:0] data_in_reg;					// input data register
//
logic [$clog2(DT)-1:0] dt_count;					// counting clks until dt (1ms)
logic dt_tick;								 		// generate tick every 1ms
logic scroll_en, scroll_wr_temp, scroll_wr_en;		// scrolling enable
logic [$clog2(NEURON_NO)-1:0] scroll_addr;			// scrolling address
logic [TD_WIDTH-1:0] time_stamp;					// time stamping

assign scroll_en = (0 < dt_count & dt_count < NEURON_NO + 1);	// for writing clk
assign rd_en = ext_rd_en | scroll_en;
assign wr_en = ext_wr_en | scroll_wr_en;
// Neuron RAM scrolling, sequentially read out all memory entries every dT 
always @(posedge clk)
	if (reset) scroll_addr <= 0;
 	else if (rd_en) scroll_addr <= (dt_tick) ? 0 : scroll_addr + 1'b1 ;

assign rd_addr = (scroll_en) ? scroll_addr : 0;

// neuron read by scrolling
always @(posedge clk)
	if (reset) scroll_data_in <= 0;
	else if (rd_en) scroll_data_in <= neuron_ram[rd_addr];

// Spike generation using Poisson spike generation module
spike_poisson #(.ACTIVITY_LEN(ACTIVITY_LEN), .REFRACTORY_LEN(REFRACTORY_LEN), .REFRACTORY_PER(REFRACTORY_PER)) spike_module (
	.clk(clk),
	.reset(reset),
	.poisson_en(scroll_en),
	.poisson_in(scroll_data_in),
	.poisson_out(scroll_data_out),
	.spike(spike));

assign data_in_reg = (scroll_wr_en) ? scroll_data_out : 0;

// delaying write address 
always @(posedge clk) begin
	wr_temp1 <= rd_addr;
	wr_temp2 <= wr_temp1;
	wr_addr <=  wr_temp2;
end

// neuron write

always @(posedge clk) begin
	scroll_wr_temp <= scroll_en;
	scroll_wr_en <= scroll_wr_temp;
end

always @(posedge clk)
	if (reset) neuron_ram[wr_addr] <= neuron_ram[wr_addr];
	else if (scroll_wr_en) neuron_ram[wr_addr] <= data_in_reg;		

// ------------------------ scrolling module -----------------------------
// dT counter 
always @(posedge clk)
	if (reset) dt_count <= 0;
	else if (rd_en) dt_count <= (dt_count < DT) ? dt_count + 1'b1 : 0;

assign dt_tick = (reset) ? 1 : (dt_count == DT-1);

// time stamping spiking information
always @(posedge clk)
	if (reset) time_stamp <= 0;
	else if (dt_tick) time_stamp <= time_stamp + 1'b1;

always @(posedge clk)
	if (reset) spiking_neur_addr <= 0;
	else if (spike) spiking_neur_addr <= {15'b0, scroll_addr};

initial begin
	for (int i=0; i<NEURON_NO; i++) begin
		if (i==0) neuron_ram[i] = 13'h1ff4;
		else if (i==1) neuron_ram[i] = 13'h1aa2;
		else if (i==255) neuron_ram[i] = 13'h1451;
		else neuron_ram[i] = 0;
	end
	dt_count = 0;
	time_stamp = 0;
	ext_rd_en = 0;
end

endmodule
