`timescale 1ns / 1ps
module spike_srm #(parameter TS_WID=12, T_FIX_WID=16) 
	(input logic 	clk, reset,
	 input logic 	[TS_WID-1:0] weight_const,
	 input logic 	[TS_WID-1:0] ampl_m, ampl_s,
	 input logic 	[T_FIX_WID-1:0] exp_m, exp_s,
	 input logic 	[TS_WID-1:0] thr, 
	 output logic 	[TS_WID-1:0] ker_m_out, ker_s_out,
	 output logic 	sp_out);

logic [T_FIX_WID-1:0] exp_m_d, exp_s_d;
logic [TS_WID-1:0] ampl_m_d, ampl_s_d;
(*use_dsp = "yes"*) logic [TS_WID+T_FIX_WID-1:0] ker_m_upsc, ker_s_upsc, ker_m_result, ker_s_result;											// spking conditions

logic [TS_WID-1:0] thr_d, mu;

always @(posedge clk)
	if (reset) begin
		exp_m_d 	<= 0;
		ampl_m_d 	<= 0;
	end
	else begin
		exp_m_d 	<= exp_m;
		ampl_m_d 	<= ampl_m;
	end

always @(posedge clk) 
	if (reset) begin
		ker_m_upsc 		<= 0;
		ker_m_result 	<= 0;
	end
	else begin
		ker_m_upsc 		<= exp_m_d*ampl_m_d;
		ker_m_result 	<= ker_m_upsc>>T_FIX_WID-1;
	end

always @(posedge clk)
	if (reset) ker_m_out <= 0;
	else ker_m_out <= ker_m_result;

always @(posedge clk)
	if (reset) begin
		exp_s_d 	<= 0;
		ampl_s_d 	<= 0;
	end
	else begin
		exp_s_d 	<= exp_s;
		ampl_s_d 	<= ampl_s;
	end

always @(posedge clk) 
	if (reset) begin
		ker_s_upsc 		<= 0;
		ker_s_result 	<= 0;
	end
	else begin
		ker_s_upsc 		<= exp_s_d*ampl_s_d;
		ker_s_result 	<= ker_s_upsc>>T_FIX_WID-1;
	end

always @(posedge clk)
	if (reset) ker_s_out <= 0;
	else ker_s_out <= ker_s_result;

always @(posedge clk) thr_d <= thr;

assign mu = ker_m_out - ker_s_out; 
assign sp_out = (mu >= thr_d) ? 1 : 0; 			// spiking condition of srm 

initial begin
	exp_m_d 	 = '0;
	ampl_m_d   	 = '0;
	exp_s_d 	 = '0;
	ampl_s_d 	 = '0;
	ker_m_upsc 	 = '0;
	ker_s_upsc 	 = '0;
	ker_m_result = '0;
	ker_s_result = '0;
	thr_d 		 = '0;
	ker_m_out 	 = '0;
	ker_s_out	 = '0;
end
endmodule