`timescale 1ns / 1ps
module sdi_gen_2byte #(parameter CLK_SCK_SCAL=40,OP_CYC=8,SER_ADDR=128,MEM_TOT=32768)
	(input logic clk, reset, csb,
	 input logic [OP_CYC-1:0] inst, status, addr1, addr2, din1, dummy,
	 input logic [$clog2(MEM_TOT/SER_ADDR)-1:0] row_cnt,
	 output logic data_out,
	 output logic [$clog2(OP_CYC*(3+SER_ADDR))-1:0] sck_cnt);

logic  inst_g1, inst_g2, inst_g3, inst_rd, inst_wr;
logic [$clog2(CLK_SCK_SCAL)-1:0] cnt;

assign inst_g1 = inst==6|inst==4|inst==96|inst==199|inst==185|inst==171|inst==121;
assign inst_g2 = inst==5;
assign inst_g3 = inst==1|inst==49;
assign inst_rd = inst==3;
assign inst_wr = inst==2;

always @(posedge clk)
	if (reset) cnt <= 0;
	else if (~csb) begin
		if (inst==11) cnt <= (cnt==CLK_SCK_SCAL/10-1) ? 0 : cnt+1;
		else if (inst_g1|inst_g2|inst_g3|inst_rd|inst_wr) cnt <= (cnt==CLK_SCK_SCAL-1) ? 0 : cnt+1;
	end
	else if (csb) cnt <= 0;

always @(posedge clk)
	if (reset) sck_cnt <= 0;
	else if (~csb) begin
		if (inst==11 & row_cnt==0) sck_cnt <= (cnt==CLK_SCK_SCAL/10-1) ? sck_cnt+1 : sck_cnt;
		else if (inst==11 & row_cnt==1) begin
			if (sck_cnt==(4+SER_ADDR)*8-1) sck_cnt <= (cnt==CLK_SCK_SCAL/10-1) ? 0 : sck_cnt;
			else sck_cnt <= (cnt==CLK_SCK_SCAL/10-1) ? sck_cnt+1 : sck_cnt;
		end
		else if (inst==11 & row_cnt>1) begin
			if (sck_cnt==(SER_ADDR)*8-1) sck_cnt <= (cnt==CLK_SCK_SCAL/10-1) ? 0: sck_cnt;
			else sck_cnt <= (cnt==CLK_SCK_SCAL/10-1) ? sck_cnt+1 : sck_cnt;
		end
		else if (inst_g1|inst_g2|inst_g3|inst_rd|inst_wr) sck_cnt <= (cnt==CLK_SCK_SCAL-1) ? sck_cnt+1 : sck_cnt;
		else sck_cnt <= 0;
	end
	else sck_cnt <= 0;

logic dout_inst, dout_status_addr1, dout_addr2, dout_din1_dummy;

assign dout_inst = (row_cnt!=0) ? 0 :((csb) ? 0 : (sck_cnt<8 ? inst[OP_CYC-1-sck_cnt] : 0));
assign dout_status_addr1 = (row_cnt!=0) ? 0 :((csb|inst_g1) ? 0 : (sck_cnt>7&sck_cnt<16 ? (inst_g3 ? status[OP_CYC*2-1-sck_cnt] : addr1[OP_CYC*2-1-sck_cnt]) : 0));
assign dout_addr2 = (row_cnt!=0) ? 0 :((inst_g1|inst_g2|inst_g3) ? 0 : (sck_cnt>15&sck_cnt<24 ? addr2[OP_CYC*3-1-sck_cnt] : 0));
assign dout_din1_dummy = (row_cnt!=0) ? 0 :((csb) ? 0 : (sck_cnt>23&sck_cnt<32 ? (inst_wr ? din1[OP_CYC*4-1-sck_cnt] : (inst==11 ? dummy[OP_CYC*4-1-sck_cnt] : 0)) : 0));
assign data_out = dout_inst|dout_status_addr1|dout_addr2|dout_din1_dummy;

initial begin
	cnt = 0;
	sck_cnt = 0;
end
endmodule