`timescale 1ns / 1ps
module device_select #(parameter NO_ROW=32, NO_COL=32, SPST_WID=4, NO_SPST=8)
	(input logic clk, reset,
	 input logic en,
	 input logic [$clos2(NO_ROW)-1:0] row_sel,
	 input logic [$clos2(NO_COL)-1:0] col_sel);

logic [$clog2(NO_ROW)-1:0] row_spst;

always @(posedge clk)
	if (reset) row_spst <= 0;
	else if (en) row_spst <= 1;	

endmodule
