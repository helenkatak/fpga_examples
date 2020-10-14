`timescale 1ns / 1ps
module int_signal #(parameter NEURON_NO=2**8)
	(input logic 	clk, reset,
	 input logic 	[1:0] ext_req,
	 input logic  	dt_tick,
	 output logic 	en,
	 output logic 	[$clog2(NEURON_NO)-1:0] n_addr);

always @(posedge clk)
	if (reset) n_addr <= '0;
	else if (ext_req) n_addr  <= n_addr;
	else if (~dt_tick) n_addr <= (n_addr==NEURON_NO-1) ? n_addr : n_addr+1;
	else n_addr <= n_addr+1;

always @(posedge clk)
	if (reset) en <= 0;
	else if (dt_tick) en  <= (~ext_req) ? 1'b1 : 0;
	else if (~ext_req) en <= (n_addr==NEURON_NO-1) ? 0 : en; 

initial begin
	en = 0;
	n_addr = NEURON_NO-1;
end
endmodule
