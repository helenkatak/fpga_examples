`timescale 1ns / 1ps
module spike_srm #(parameter TS_WID=20, T_FIX_WID=16) 
	(input logic clk, reset,
	 input logic update_en,	
	 input logic sp_in,
	 input logic [TS_WID-1:0] ampl_a_val, ampl_b_val,
	 input logic [T_FIX_WID-1:0] exp_func_val_a, exp_func_val_b,
	 input logic [TS_WID-1:0] thr, 
	 output logic [TS_WID+T_FIX_WID-1:0] ker_a, ker_b,
	 output logic sp_out,									
	 output logic [TS_WID-1:0] mu_out,
	 output logic srm_en_d);

localparam w = 10;														// FXnum(0.01, FXfamily(10,1))
localparam tau_m = 40;  												// FXnum(0.04, FXfamily(10,1))
localparam tau_s = 10;  												// FXnum(0.01, FXfamily(20,2))
localparam umem_const = 1398101;										// FXnum(0.04/(0.04-0.01), FXfamily(20,4))
localparam w_umem_const = 13981;										// FXnum(0.01*0.04/0.03, FXfamily(20,1))
localparam THR_VAL = 5242;	


logic srm_en;															// delayed comparison enable signal
logic [TS_WID-1:0] mu_in, mu_in_d;										// mu threshold and delayed mu_in
(*use_dsp = "yes"*) logic [TS_WID+T_FIX_WID-1:0] ker_a_upsc, ker_b_upsc;
(*use_dsp = "yes"*) logic [TS_WID-1:0] mu_out;							// mu upscaled and comparison redult
logic srm_spiking_cond;													// spking conditions
logic [TS_WID-1:0] data_reg;								

always @(posedge clk) begin
	srm_en 		<= update_en;
	srm_en_d 	<= srm_en;
end

always @(posedge clk) 
	if (reset) begin
		ker_a_upsc <= 0;
		ker_b_upsc <= 0;
	end
	else begin
		ker_a_upsc <= ampl_a_val * exp_func_val_a;
		ker_b_upsc <= ampl_b_val * exp_func_val_b;
	end

assign ker_a = (sp_in) ? w_umem_const + ker_a_upsc[TS_WID+T_FIX_WID-1:T_FIX_WID-1] : ker_a_upsc[TS_WID+T_FIX_WID-1:T_FIX_WID-1]; // kernal a
assign ker_b = (sp_in) ? w_umem_const + ker_b_upsc[TS_WID+T_FIX_WID-1:T_FIX_WID-1] : ker_b_upsc[TS_WID+T_FIX_WID-1:T_FIX_WID-1]; // kernal b
assign mu_in = ker_a - ker_b; 											// Neuron membrain potential

always @(posedge clk)
	if (reset) mu_in_d <= 0;
	else mu_in_d <= (srm_en) ? mu_in[TS_WID-1:0] : 0;	

assign srm_spiking_cond = (srm_en_d) ? (mu_in_d >= thr) : 0; 			// spiking condition of srm 

assign sp_out = (srm_spiking_cond) ? 1'b1 : 0;

always @(posedge clk) 
	if (reset) data_reg <= 0;
	else if (sp_out) data_reg <= '0;
	else data_reg <= mu_in_d;

assign mu_out = data_reg;

initial begin
	srm_en = '0;
	srm_en_d = '0;
	mu_in_d = '0;
	ker_a_upsc = '0;
	ker_b_upsc = '0;
	data_reg = '0;
end
endmodule
