`timescale 1ns / 1ps
module piso
	(input logic clk, reset,
	 input logic piso_en,
	 input logic [2:0] piso_cnt,
	 input logic [2:0] par_in,
	 output logic piso_end,
	 output logic ser_out);

logic [2:0] cnt;

always @(posedge clk) 
	if (reset) cnt <= 0;
	else cnt <= piso_cnt;
	
assign ser_out = (piso_en) ? ((cnt == par_in) ? 1 : 0) : 0;

assign piso_end = (cnt == 8-1) ? 1 : 0;

initial begin
	cnt = 0;
end
endmodule
