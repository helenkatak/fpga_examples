`timescale 1ns / 1ps
module exponetial_module
	(input logic clk, reset,
	 input logic spike_in,
	 output real out);


localparam W_MAX = 1;
localparam BIN_SIZE = 8;
localparam TAU = 2;
localparam T_SIZE = 4;

real BASE = 2.78;
real y = 0.00;

logic [T_SIZE-1:0] t; 		// t cycles within 8 

// counter 
always @(posedge clk) 
	if (reset) t <= 0;
	else if (spike_in) t <= 1'b1;
	else t <= (t==0) ? 0 : t + 1;


always @(posedge clk)
	if (reset) y <= 0;
	else y <= (t==0) ? 0 : W_MAX*BASE**(-t/TAU);

assign out = $rtoi(y);

initial begin
	t = 0;
end
endmodule
