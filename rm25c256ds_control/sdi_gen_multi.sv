`timescale 1ns / 1ps
module sdi_gen_multi #(parameter CLK_SCK_SCAL=40, OP_CYC=8, NO_ADDR=4)
	(input logic clk, reset, csb,
	 input logic [OP_CYC-1:0] inst,
	 input logic [OP_CYC-1:0] addr1, addr2,
	 input logic [OP_CYC-1:0] dummy,
	 output logic data_out,
	 output logic [$clog2(OP_CYC*(4+NO_ADDR))-1:0] sck_cnt);

logic [$clog2(CLK_SCK_SCAL)-1:0] cnt;

always @(posedge clk)
	if (reset) cnt <= 0;
	else if (~csb) cnt <= (cnt==CLK_SCK_SCAL-1) ? 0 : cnt + 1;

always @(posedge clk)
	if (reset) sck_cnt <= 0;
	else if (cnt==CLK_SCK_SCAL-1) sck_cnt <= sck_cnt + 1;
	else if (csb) sck_cnt <= 0;

assign data_out = csb ? 0 : (sck_cnt<8 ? inst[OP_CYC-1-sck_cnt] : (sck_cnt<16 ? addr1[OP_CYC*2-1-sck_cnt] : (sck_cnt<24 ? addr2[OP_CYC*3-1-sck_cnt] : (sck_cnt<32 ? (inst==11 ? dummy[OP_CYC*4-1-sck_cnt] : 0) : 0)))); 

initial begin
	cnt = 0;
	sck_cnt = 0;
end
endmodule

