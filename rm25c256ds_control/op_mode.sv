`timescale 1ns / 1ps
module op_mode #(parameter SER_LEN=8) 
	(input logic clk, reset, rx_done,
	 input logic [SER_LEN-1:0] rx_dout,
	 output logic [SER_LEN-1:0] inst, status, addr1, addr2, din1, dummy,
	 output logic sysen,
	 output logic [1:0] ser_rd);

logic rx_dout_g1, rx_done_d; 
logic [1:0] op_cnt;
logic sysen_pre;

logic  inst_g1, inst_g2, inst_g3, inst_rd, inst_wr, inst_norm, inst_frd;
logic rx_dout_norm;

assign rx_dout_g1 = rx_dout==6|rx_dout==4|rx_dout==96|rx_dout==199|rx_dout==185|rx_dout==171|rx_dout==121;
assign inst_g1 = inst==6|inst==4|inst==96|inst==199|inst==185|inst==171|inst==121;
assign inst_g2 = inst==5;
assign inst_g3 = inst==1|inst==49;
assign inst_rd = inst==3;
assign inst_wr = inst==2;
assign inst_norm = inst_g1|inst_g2|inst_g3|inst_rd|inst_wr;
assign inst_frd = inst==11;
assign inst_pers = inst==66;

assign rx_dout_norm = rx_dout_g1|rx_dout==5|rx_dout==1|rx_dout==49|rx_dout==3|rx_dout==2;

always @(posedge clk)
	if (reset) op_cnt <= 0;
	else if (rx_done) 
		if (op_cnt==0) op_cnt <= (rx_dout_g1|rx_dout==5) ? 0 : ((rx_dout==1|rx_dout==49|rx_dout==3|rx_dout==2|rx_dout==11|rx_dout==33|rx_dout==34) ? op_cnt+1 : 0);
		else if (op_cnt==1) op_cnt <= (inst_g3) ? 0 : op_cnt+1; 
		else if (op_cnt==2) op_cnt <= (inst_rd) ? 0 : op_cnt+1;  //READ
		else if (op_cnt==3) op_cnt <= (inst_wr) ? 0 : op_cnt+1;	 //WR

always @(posedge clk) 
 	if (reset) inst <= 0;
	else if (rx_done&op_cnt==0)
		if (rx_dout==33|rx_dout==34) inst <= 3;
		else if (rx_dout_norm|rx_dout==11) inst <= rx_dout;
		else inst <= 0;

always @(posedge clk) 
	if (reset) ser_rd <= 0;
	else if (rx_done) ser_rd <= (op_cnt==0) ? (rx_dout==33 ? 1 : (rx_dout==34 ? 2 : 0)) : ser_rd;

always @(posedge clk)
	if (reset) status <= 0;
	else if (rx_done) status <= (op_cnt==1&inst_g3) ? rx_dout : status;

always @(posedge clk)
	if (reset) begin 
		addr1 <= 0;
		addr2 <= 0;
	end
	else if (rx_done) begin
		addr1 <= op_cnt==1&(inst_rd|inst_wr|inst_frd) ? rx_dout : addr1;
		addr2 <= op_cnt==2&(inst_rd|inst_wr|inst_frd) ? rx_dout : addr2;
	end

always @(posedge clk)
	if (reset) begin
		din1 <= 0;
		dummy <= 0;
	end
	else if (rx_done) begin
		din1 <= op_cnt==3&inst_wr ? rx_dout : din1;
		dummy <= op_cnt==3&inst_frd ? rx_dout : dummy;
	end

always @(posedge clk) rx_done_d <= rx_done;

always @(posedge clk)
	if (reset) begin
		sysen_pre <= 0;
		sysen <= 0;
	end
	else if (inst_norm|inst_frd) begin
		sysen_pre <= op_cnt==0&rx_done_d;
		sysen <= sysen_pre;
	end

initial begin
	inst = 0;
	status = 0;
	addr1 = 0;
	addr2 = 0;
	din1 = 0;
	dummy = 0;
	op_cnt = 0;
	rx_done_d = 0;
	sysen_pre = 0;
	sysen = 0;
	ser_rd = 0;
end
endmodule
