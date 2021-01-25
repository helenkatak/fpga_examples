`timescale 1ns / 1ps
module sdo_read #(parameter OP_CYC=16, SER_LEN=8, SER_ADDR=16)
	(input logic clk, reset, sck,
	 input logic [SER_LEN-1:0] inst,
	 input logic [1:0] ser_rd,
	 input logic [$clog2(OP_CYC*(3+SER_ADDR))-1:0] sck_cnt,
	 input logic sdo_port,
	 output logic sdo_par_rdy,
	 output logic [SER_LEN-1:0] sdo_par,
	 output logic din_rdy, sdo_ser);

logic sck_d, din_rdy_d;
logic sdo_par_rdy_pre;

always @(posedge clk) sck_d <= sck; 

assign din_rdy = (inst==5) ? (sck_cnt>7&~sck_d&sck) : ((inst==11) ? (sck_cnt>31&~sck_d&sck) : (sck_cnt>23&~sck_d&sck));

always @(posedge clk) din_rdy_d <= din_rdy;

always @(posedge clk)
	if (reset) sdo_ser <= 0;
	else sdo_ser <= sdo_port;

logic [2:0] sck_cnt_md;
assign sck_cnt_md = sck_cnt[2:0];

always @(posedge clk)
	if (reset) sdo_par <= 0;
	else if (din_rdy) 
		if 		(sck_cnt_md==0)	sdo_par[7] <= sdo_ser;
		else if (sck_cnt_md==1) sdo_par[6] <= sdo_ser;
		else if (sck_cnt_md==2) sdo_par[5] <= sdo_ser;
		else if (sck_cnt_md==3) sdo_par[4] <= sdo_ser;
		else if (sck_cnt_md==4) sdo_par[3] <= sdo_ser;
		else if (sck_cnt_md==5) sdo_par[2] <= sdo_ser;
		else if (sck_cnt_md==6) sdo_par[1] <= sdo_ser;
		else if (sck_cnt_md==7) sdo_par[0] <= sdo_ser;
	else sdo_par <= sdo_par;

assign sdo_par_rdy_pre = (inst==5) ? (sck_cnt==15&din_rdy_d) : (inst==3|inst==11 ? sck_cnt[2:0]==7&din_rdy_d : 0); 

always @(posedge clk) 
	if (reset) sdo_par_rdy <= 0;
	else if (ser_rd<2) sdo_par_rdy <= sdo_par_rdy_pre;

initial begin
	sck_d 		= 0;
	din_rdy_d 	= 0;
	sdo_ser 	= 0;
	sdo_par_rdy = 0;
	sdo_par 	= 0;
end
endmodule