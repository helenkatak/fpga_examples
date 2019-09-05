`timescale 1ns / 1ps
module spike_poisson #(parameter ACTIVITY_LEN=9, REFRACTORY_LEN=4, REFRACTORY_PER=4) 
	(input logic clk, reset,
	 input logic poisson_en,
	 input logic [NEUR_MEM_LEN-1:0] poisson_in,					// Read neuron memory
	 output logic [NEUR_MEM_LEN-1:0] poisson_out,			
	 output logic spike_out);

localparam NEUR_MEM_LEN = ACTIVITY_LEN + REFRACTORY_LEN;
localparam LFSR_LEN = 16;

logic [LFSR_LEN-1:0] lfsr_out;									// Generate RN when poisson_en signal is high
logic [ACTIVITY_LEN-1:0] activity, activity_d;	
logic [ACTIVITY_LEN+REFRACTORY_PER-1:0] activity_shift;	
logic [REFRACTORY_LEN-1:0] dt_lev, dt_lev_new;
logic poisson_spiking_cond, dt_cond;	
logic spike;	
logic [NEUR_MEM_LEN-1:0] data_reg; 			

// Splite activity and refractory state from neuron input 
assign activity = (poisson_en) ? poisson_in[NEUR_MEM_LEN-1:REFRACTORY_LEN] : 3'b000;	
assign dt_lev = (poisson_en) ? poisson_in[REFRACTORY_LEN-1:0] : 2'b00;

lfsr #(.LFSR_LEN(LFSR_LEN)) lfsr_module (
	.clk(clk),
	.reset(reset),
	.lfsr_en(poisson_en),
	.lfsr_out(lfsr_out));

// synchronize different enable signals to lfsr ready signals
assign activity_shift = (activity << REFRACTORY_PER);

// spiking condition of poisson generator and time resolution
assign poisson_spiking_cond = (lfsr_out <= 1) ? 0 : (activity_shift >= lfsr_out); 	
assign dt_cond = (lfsr_out <= 1) ? 0 : ((dt_lev == 0) ? 1 : 0);			

// If refractory state is not zero, then decrement it every dT; 
// If it is zero, either leave it at zero (no spike) or set it to refractory period (spike)

always @(posedge clk) begin
	activity_d <= activity;
end

always @(posedge clk)
	if (reset) dt_lev_new <= 0;
	else if (poisson_en) dt_lev_new <= (dt_lev > 0) ? dt_lev - 1'b1 : 0; 

always @(posedge clk) 
	if (reset) data_reg <= 0;
	else if (spike) data_reg = (activity_d << REFRACTORY_PER) + 4'h3;
	else if (~spike) data_reg <= {activity_d, dt_lev_new};

always @(posedge clk)
	if (reset) spike <= 0;
	else spike <= (poisson_spiking_cond & dt_cond) ? 1'b1 : 0;

assign spike_out = spike;
assign poisson_out = data_reg;

initial begin
	activity_d = 0;
	dt_lev_new = 0;
	spike = 0;
	data_reg = 0;
end
endmodule
