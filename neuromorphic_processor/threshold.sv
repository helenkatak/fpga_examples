`timescale 1ns / 1ps
module threshold #(parameter NEURON_NO=2**8, THR=5000, TS_WID=20, T_FIX_WID=16) 
	(input logic clk, reset,
	 input logic [T_FIX_WID-1:0] thr_ts_efa_out,
	 input logic [NEURON_NO-1:0] t_thr_flag,
	 input logic [$clog2(NEURON_NO)-1:0] t_thr_rd_addr,
	 output logic [TS_WID-1:0] thr);

logic [T_FIX_WID-1:0] thr_ts_efa_out_d;

always @(posedge clk)
	thr_ts_efa_out_d <= thr_ts_efa_out;

always @(posedge clk)
	if (reset) thr <= THR;
	else thr <= (t_thr_flag[t_thr_rd_addr]) ? THR + thr_ts_efa_out : THR;

initial begin
	thr = THR;
	thr_ts_efa_out_d = '0;
end
endmodule
