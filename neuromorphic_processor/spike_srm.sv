`timescale 1ns / 1ps
module spike_srm #(parameter MU_LEN=32, EXP_LEN=16, AMPL_LEN=24, 
							 REFRACTORY_LEN=4,REFRACTORY_PER=4) 
	(input logic clk, reset,
	 input logic srm_en,	
	 input logic sp_in,
	 input logic [AMPL_LEN-1:0] ampl_val,
	 input logic [EXP_LEN-1:0] exp_func_val,
	 input logic [REFRACTORY_LEN-1:0] ref_per_val,	
	 output logic [MU_LEN-1:0] mu_in,
	 output logic sp_out,									
	 output logic [MU_LEN+REFRACTORY_LEN-1:0] mu_out);

localparam w = 16'h028f;
logic srm_en_d;															// delayed comparison enable signal
logic [REFRACTORY_LEN-1:0] dt_lev, dt_lev_new;							// refractory period counting
logic [MU_LEN-1:0] thr, mu_in_d;										// mu threshold and delayed mu_in
(*use_dsp = "yes"*) logic [MU_LEN+REFRACTORY_LEN-1:0] mu_upsc, mu_out;	// mu upscaled and comparison redult
logic srm_spiking_cond, dt_cond;										// spking conditions
logic [MU_LEN+REFRACTORY_LEN-1:0] data_reg;								

always @(posedge clk)
	srm_en_d <= srm_en;

always @(posedge clk) 
	if (reset) mu_upsc <= 0;
	else mu_upsc <= ampl_val * exp_func_val;

assign mu_in = (sp_in) ? w + mu_upsc[MU_LEN-1:15] : mu_upsc[MU_LEN-1:15]; // Neuron membrain potential

always @(posedge clk)
	if (reset) mu_in_d <= 0;
	else mu_in_d <= (srm_en) ? mu_in : 0;	

assign srm_spiking_cond = (srm_en_d) ? (mu_in_d >= thr) : 0; 	// spiking condition of srm and time resolution

always @(posedge clk) 
	if (reset) dt_lev <= 0;
	else dt_lev <= (srm_en) ? ref_per_val : 0;

// If it is zero, either leave it at zero (no spike) or set it to refractory period (spike)
assign dt_cond = (srm_en_d) ? ((dt_lev == 0) ? 1 : 0) : 0;		

// If refractory state is not zero, then decrement it every dT; 
always @(posedge clk)
	if (reset) dt_lev_new <= 0;
	else dt_lev_new <= (dt_lev > 0) ? dt_lev - 1'b1 : 0; 

assign sp_out = (srm_spiking_cond & dt_cond) ? 1'b1 : 0;

always @(posedge clk) 
	if (reset) data_reg <= 0;
	else if (sp_out) data_reg <= (mu_in_d << REFRACTORY_PER) + 4'h4;
	else if (~sp_out) data_reg <= {mu_in_d, dt_lev_new};

assign mu_out = data_reg;

initial begin
	thr = 1000;
	srm_en_d = '0;
	mu_in_d = '0;
	mu_upsc = '0;
	dt_lev = '0;
	dt_lev_new = '0;
	data_reg = '0;
end
endmodule
