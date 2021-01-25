`timescale 1ns / 1ps
module sdi_gen_1byte #(parameter CLK_SCK_SCAL=40, OP_CYC=8)
	(input logic clk, reset, csb,
	 input logic [OP_CYC-1:0] inst,
	 input logic [OP_CYC-1:0] status,
	 output logic data_out,
	 output logic [$clog2(OP_CYC*2)-1:0] sck_cnt);

logic [$clog2(CLK_SCK_SCAL)-1:0] cnt;

always @(posedge clk)
	if (reset) cnt <= 0;
	else if (~csb) cnt <= (cnt==CLK_SCK_SCAL-1) ? 0 : cnt + 1;

always @(posedge clk)
	if (reset) sck_cnt <= 0;
	else if (cnt==CLK_SCK_SCAL-1) sck_cnt <= sck_cnt + 1;
	else if (csb) sck_cnt <= 0;

assign data_out = (csb) ? 0 : (sck_cnt<8 ? inst[OP_CYC-1-sck_cnt] : status[OP_CYC*2-1-sck_cnt]); 

initial begin
	cnt = 0;
	sck_cnt = 0;
end
endmodule
