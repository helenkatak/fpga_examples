`timescale 1ns / 1ps
module threshold #(parameter NEURON_NO=2**8, THR=5000, TS_WID=12, T_FIX_WID=16) 
	(input logic clk, reset,
	 input logic [T_FIX_WID-1:0] thr_ts_efa_out, t_thr_reg,
	 output logic [TS_WID-1:0] thr);

logic [T_FIX_WID-1:0] thr_ts_efa_out_d;

always @(posedge clk)
	thr_ts_efa_out_d <= thr_ts_efa_out[T_FIX_WID-1:T_FIX_WID-TS_WID];

always @(posedge clk)
	if (reset) thr <= THR;
	else thr <= (t_thr_reg) ? THR + thr_ts_efa_out_d : THR;

initial begin
	thr = THR;
	thr_ts_efa_out_d = '0;
end
endmodule
