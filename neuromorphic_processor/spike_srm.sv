`timescale 1ns / 1ps
module spike_srm #(parameter TS_WID=20, T_FIX_WID=16) 
	(input logic clk, reset,
	 input logic update_en,	
	 input logic sp_in,
	 input logic sel,
	 input logic [TS_WID-1:0] weight,
	 input logic [TS_WID-1:0] ampl_a_val, ampl_b_val,
	 input logic [T_FIX_WID-1:0] exp_func_val_a, exp_func_val_b,
	 input logic [TS_WID-1:0] thr, 
	 output logic [TS_WID-1:0] ker_a, ker_b,
	 output logic sp_out,									
	 output logic [TS_WID-1:0] mu_out);

logic srm_en, srm_en_d;															// delayed comparison enable signal
logic [TS_WID-1:0] mu_in;										// mu threshold and delayed mu_in
(*use_dsp = "yes"*) logic [TS_WID+T_FIX_WID-1:0] ker_a_upsc, ker_b_upsc;
(*use_dsp = "yes"*) logic [TS_WID-1:0]  ker_a_result, ker_b_result;											// spking conditions
logic [TS_WID-1:0] data_reg;								
(*use_dsp = "yes"*) logic sp_out;
(*use_dsp = "yes"*) logic [TS_WID-1:0] thr;

always @(posedge clk) begin
	srm_en 		<= update_en;
	srm_en_d 	<= srm_en;
end

always @(posedge clk) 
	if (reset) begin
		ker_a_upsc <= 0;
		ker_a_result <= 0;
		ker_b_upsc <= 0;
		ker_b_result <= 0;
	end
	else begin
		ker_a_upsc <= ampl_a_val * exp_func_val_a;
		ker_a_result <= ker_a_upsc>>T_FIX_WID-1;
		ker_b_upsc <= ampl_b_val * exp_func_val_b;
		ker_b_result <= ker_b_upsc>>T_FIX_WID-1;
	end

assign ker_a = (sp_in) ? weight + ker_a_result : ker_a_result; 			// kernal a
assign ker_b = (sp_in) ? weight + ker_b_result : ker_b_result;  			// kernal b

assign mu_in = ker_a - ker_b; 											// Neuron membrain potential
assign sp_out = (srm_en&~sel) ? (mu_in >= thr) : 0; 			// spiking condition of srm 

always @(posedge clk) 
	if (reset) data_reg <= 0;
	else if (sp_out) data_reg <= '0;
	else data_reg <= mu_in;

assign  mu_out = data_reg;

initial begin
	srm_en = '0;
	srm_en_d = '0;
	ker_a_upsc = '0;
	ker_b_upsc = '0;
	ker_a_result = '0;
	ker_b_result = '0;
	data_reg = '0;
end
endmodule
