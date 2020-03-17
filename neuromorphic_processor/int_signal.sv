`timescale 1ns / 1ps
module int_signal #(parameter NEURON_NO=2**8)
	(input logic 	clk, reset, sys_en,
	 input logic 	[1:0] ext_req,
	 input logic  	dt_tick,
	 output logic 	testing_en,
	 output logic 	[$clog2(NEURON_NO)-1:0] testing_addr,
	 output logic 	sel);

always @(posedge clk)
	if (reset) testing_addr <= '0;
	else if (ext_req) testing_addr <=testing_addr;
	else if (~dt_tick) testing_addr <= (testing_addr==NEURON_NO-1) ? testing_addr : ((sel==1) ? testing_addr : testing_addr + 1'b1);
	else testing_addr <=(sel==1) ? testing_addr : testing_addr + 1'b1;

always @(posedge clk)
	if (reset) testing_en <= 0;
	else if (dt_tick) testing_en 	<= (~ext_req) ? 1'b1 : 0;
	else if (~ext_req) testing_en 	<= (testing_addr==NEURON_NO-1) ? 0 : testing_en;

always @(posedge clk)
	if (reset) sel <= 0;
	else if (dt_tick) sel <= 1;
	else sel <= ~sel;

initial begin
	testing_addr = NEURON_NO-1;
	testing_en = 0;
	sel = 0;
end
endmodule
