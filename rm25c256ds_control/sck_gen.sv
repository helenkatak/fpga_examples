`timescale 1ns / 1ps
module sck_gen #(parameter CLK_SCK_SCAL=40, SER_LEN=8) 
	(input logic clk, reset, csb,
	 input logic [SER_LEN-1:0] inst,
	 output logic sck);

logic [$clog2(CLK_SCK_SCAL/2)-1:0] clk_cnt;

assign inst_g1 = inst==6|inst==4|inst==96|inst==199|inst==185|inst==171|inst==121;
assign inst_g2 = inst==5;
assign inst_g3 = inst==1|inst==49;
assign inst_rd = inst==3;
assign inst_wr = inst==2;
assign inst_frd = inst ==11;

always @(posedge clk)
	if (reset) clk_cnt <= 0;
	else if (inst_frd) begin
		if (~csb) clk_cnt <= (clk_cnt==CLK_SCK_SCAL/10/2-1) ? 0 : clk_cnt +1;
		else clk_cnt <= 0;
	end
	else begin
		if (~csb) clk_cnt <= (clk_cnt==CLK_SCK_SCAL/2-1) ? 0 : clk_cnt + 1;
	end

always @(posedge clk)
	if (reset) sck <= 0;
	else if (inst_frd) begin
		if (~csb) sck <= (clk_cnt == CLK_SCK_SCAL/10/2-1) ? ~sck : sck;
		else sck <= 0;
	end
	else begin
		if (~csb) sck <= (clk_cnt == CLK_SCK_SCAL/2-1) ? ~sck : sck;
		else sck <= 0;
	end

initial begin
	clk_cnt = 0;
	sck = 0;
end
endmodule
