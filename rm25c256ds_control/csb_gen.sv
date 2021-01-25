`timescale 1ns / 1ps
module csb_gen #(parameter CLK_SCK_SCAL=40, OP_CYC=8, SER_LEN=8, SER_ADDR=16) 
	(input logic clk, reset, sysen, 
	 input logic [1:0] ser_rd,
	 input logic [SER_LEN-1:0] inst,
	 output logic csb_pre, csb);

localparam OP_PER = CLK_SCK_SCAL*OP_CYC;
localparam CSB_MAX = OP_PER*(3+SER_ADDR)-1;
localparam INI_CSB_MAX = OP_PER*3-1;
localparam D_CSB_MAX = OP_PER*SER_ADDR-1;

logic csb_d, csb_2d, csb_3d;
logic inst_g1, inst_g2, inst_g3;
logic [$clog2(OP_PER*3)-1:0] ini_csb_cnt;
logic [$clog2(OP_PER*SER_ADDR)-1:0] d_csb_cnt;
logic csb_4d, csb_5d;

assign inst_g1 = inst==6|inst==4|inst==96|inst==199|inst==185|inst==171|inst==121;
assign inst_g2 = inst==5;
assign inst_g3 = inst==1|inst==49;

always @(posedge clk)
	if (reset) ini_csb_cnt <= OP_PER*3-1;
	else if (sysen) ini_csb_cnt <= 0;
	else if (inst_g1|inst_g2|inst_g3) ini_csb_cnt <= (ini_csb_cnt==INI_CSB_MAX) ? INI_CSB_MAX : ini_csb_cnt+1;
	else if (inst==11) ini_csb_cnt <= (ini_csb_cnt==(INI_CSB_MAX+1)/10-1|ini_csb_cnt==INI_CSB_MAX) ? INI_CSB_MAX : ini_csb_cnt+1;
	else ini_csb_cnt<= (ini_csb_cnt==OP_PER*3-1|ini_csb_cnt==INI_CSB_MAX) ? INI_CSB_MAX : ini_csb_cnt+1;

always @(posedge clk)
	if (reset) d_csb_cnt <= D_CSB_MAX;
	else if (inst==11) begin
		if (ini_csb_cnt==(INI_CSB_MAX+1)/10-1) d_csb_cnt <= 0;
		else d_csb_cnt <= (d_csb_cnt==D_CSB_MAX/10|d_csb_cnt==D_CSB_MAX) ? D_CSB_MAX : d_csb_cnt+1;
	end
	else if (inst==3|inst==2) begin
		if (ini_csb_cnt==INI_CSB_MAX-1) d_csb_cnt <= 0;
		else if (ser_rd==0) d_csb_cnt <= (d_csb_cnt==OP_PER-1|d_csb_cnt==D_CSB_MAX) ? D_CSB_MAX : d_csb_cnt+1;
		else if (ser_rd>=1) d_csb_cnt <= (d_csb_cnt==D_CSB_MAX) ? D_CSB_MAX : d_csb_cnt+1;
	end

always @(posedge clk)
	if (reset) csb_pre <= 1;
	else if (sysen) csb_pre <= 0;
	else if (inst_g1) csb_pre <= (ini_csb_cnt==OP_PER-1) ? 1 : csb_pre;
	else if (inst_g2|inst_g3) csb_pre <= (ini_csb_cnt==OP_PER*2-1) ? 1 : csb_pre;
	else if (inst==3|inst==2) csb_pre <= (ini_csb_cnt<INI_CSB_MAX) ? csb_pre : ((d_csb_cnt==D_CSB_MAX) ? 1 : csb_pre);
	else if (inst==11) csb_pre <= (ini_csb_cnt<(INI_CSB_MAX+1)/10-1) ? csb_pre : ((d_csb_cnt==(D_CSB_MAX+1)/10-1) ? 1 : csb_pre);
	else csb_pre <= csb_pre;

always @(posedge clk) begin
	csb_d <= csb_pre;
	csb_2d <= csb_d;
	csb_3d <= csb_2d;
	csb_4d <= csb_3d;
	csb_5d <= csb_4d;
end

assign csb = csb_5d & csb_pre;

initial begin
	ini_csb_cnt = INI_CSB_MAX;
	d_csb_cnt = D_CSB_MAX;
	csb_pre = 1;
	csb_d 	= 1;
	csb_2d 	= 1;
	csb_3d 	= 1;
	csb_4d 	= 1;
	csb_5d 	= 1;
end
endmodule