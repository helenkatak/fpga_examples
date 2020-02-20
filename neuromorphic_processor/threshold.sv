`timescale 1ns / 1ps
module threshold #(parameter NEURON_NO=2**8, THR_VAL=5000, TS_WID=20, T_FIX_WID=16) 
	(input logic clk, reset,
	 input logic [T_FIX_WID-1:0] thr_ts_efa_out,
	 input logic [T_FIX_WID-1:0] t_thr_temp,
	 output logic [TS_WID-1:0] thr);

localparam uref = 2097;							// FXnum(0.002, FXfamily(20,2))
localparam tau_m = 41943;  						// FXnum(0.04, FXfamily(20,2))
localparam thr_const = 52428; 					// uref/tau_m = 2097/41943 = 0.002/0.04 = 0.05

logic [T_FIX_WID-1:0] t_thr_reg, t_thr_reg_d; 
logic [TS_WID+T_FIX_WID-1:0] thr_upsc;
logic [$clog2(NEURON_NO)-1:0] t_thr_wr_addr, t_thr_rd_addr_d;

always @(posedge clk) 
	if (reset) thr_upsc <= 0;
	else thr_upsc <= thr_const * thr_ts_efa_out;

always @(posedge clk)
	if (reset) thr <= THR_VAL;
	else thr <= (t_thr_temp==0) ? THR_VAL : THR_VAL + thr_upsc[TS_WID+T_FIX_WID-1:T_FIX_WID-1];
	// + instead of - for avoiding negative

initial begin
	thr = THR_VAL;
	thr_upsc = '0;
end
endmodule
