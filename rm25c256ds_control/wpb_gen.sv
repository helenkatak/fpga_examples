`timescale 1ns / 1ps
module wpb_gen #(parameter CLK_SCK_SCAL=40, WP_CYC=16) 
	(input logic clk, reset, wr_pause,
	 output logic wpb);

localparam WP_PER = CLK_SCK_SCAL*WP_CYC;

logic [$clog2(WP_PER)-1:0] wpb_cnt;

always @(posedge clk)
	if (reset) wpb_cnt <= 0;
	else if (wr_pause) wpb_cnt <= 0;
	else wpb_cnt <= (wpb_cnt==WP_PER-1) ? wpb_cnt : wpb_cnt + 1;

always @(posedge clk)
	if (reset) wpb <= 1;
	else if (wr_pause) wpb <= 0;
	else if (wpb_cnt==WP_PER-1) wpb <= 1;  
	else wpb = wpb;

initial begin
	wpb_cnt = WP_PER-1;
	wpb = 1;
end
endmodule