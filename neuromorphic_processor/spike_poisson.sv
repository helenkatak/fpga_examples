`timescale 1ns / 1ps
module spike_poisson #(parameter ACTIVITY_LEN = 9, REFRACTORY_LEN = 4, REFRACTORY_PER = 4) 
	(input logic clk, reset,
	 input logic poisson_en,
	 input logic [NEUR_MEM_LEN-1:0] poisson_in,	
	 output logic [NEUR_MEM_LEN-1:0] poisson_out,			
	 output logic spike);

localparam NEUR_MEM_LEN = ACTIVITY_LEN + REFRACTORY_LEN;
localparam LFSR_LEN = 16;

logic [ACTIVITY_LEN-1:0] activity, activity_d;	
logic [ACTIVITY_LEN+REFRACTORY_PER-1:0] activity_shift;	
logic [REFRACTORY_LEN-1:0] dt_lev, dt_lev_new;
logic poisson_spiking_cond, dt_cond;					
logic [LFSR_LEN-1:0] lfsr_out;


// splite activity and refractory state from neuron input 
assign activity = poisson_in[NEUR_MEM_LEN-1:REFRACTORY_LEN];	
assign dt_lev = poisson_in[REFRACTORY_LEN-1:0];

lfsr #(.LFSR_LEN(LFSR_LEN)) lfsr_module (
	.clk(clk),
	.reset(reset),
	.en(poisson_en),
	.lfsr_out(lfsr_out));

// synchronize different enable signals to lfsr ready signals
assign activity_shift = activity << REFRACTORY_PER;

// spiking condition of poisson generator and time resolution
assign poisson_spiking_cond = (activity_shift >= lfsr_out); 	
assign dt_cond = (dt_lev == 0);			

// If refractory state is not zero, then decrement it every dT; 
// If it is zero, either leave it at zero (no spike) or set it to refractory period (spike)

// assign dt_lev_new = (dt_cond) ? ((dt_lev == 0) ? 0 : REFRACTORY_PER) : dt_lev - 1'b1;
always @(posedge clk)
	activity_d <= activity;

always @(posedge clk)
	dt_lev_new <= (dt_lev != 0) ? dt_lev - 1'b1 : 0;

// always @(posedge clk) begin
//  	if (dt_cond) dt_lev_new <= 0;
//  	else dt_lev_new <= dt_lev - 1'b1;
//  	if (spike) dt_lev_new <= REFRACTORY_PER;
// end

always @(posedge clk) 
	if (spike) poisson_out <= {activity_d, 4'b0100};
	else if (poisson_en) poisson_out <= {activity_d, dt_lev_new};

always @(posedge clk)
	if (reset) spike <= 0;
	else spike <= (poisson_spiking_cond & dt_cond) ? 1'b1 : 0;

endmodule
