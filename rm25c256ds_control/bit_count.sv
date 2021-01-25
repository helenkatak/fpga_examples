`timescale 1ns / 1ps
module bit_count #(parameter OP_CYC=16, SER_LEN=8, SER_ADDR=16)
	(input logic clk, reset,
	 input logic sdo_ser, sdo_ser_rdy,
	 input logic [$clog2(OP_CYC*(3+SER_ADDR))-1:0] sck_cnt,
	 output logic [$clog2(SER_ADDR*SER_LEN):0] cnt_val,
	 output logic cnt_val_rdy);

logic [$clog2(SER_ADDR*SER_LEN):0] cnt;
logic sdo_ser_rdy_d;
logic [$clog2(OP_CYC*(SER_ADDR))-1:0] sck_cnt_sub;

assign sck_cnt_sub = (sck_cnt>=3*SER_LEN) ? sck_cnt-3*SER_LEN : 0;

always @(posedge clk) sdo_ser_rdy_d <= sdo_ser_rdy;

always @(posedge clk)
	if (reset) cnt <= 0;
	else if (sdo_ser_rdy) cnt <= cnt + sdo_ser;
	else if (sdo_ser_rdy_d) cnt <= (sck_cnt_sub[6:0]==127) ? 0 : cnt;
	else if (sck_cnt==0) cnt <= 0;

always @(posedge clk) 
	if (reset) cnt_val <= 0;
	else cnt_val <= sdo_ser_rdy_d&(sck_cnt_sub[6:0]==127) ? cnt : cnt_val;

always @(posedge clk)
	if (reset) cnt_val_rdy <= 0;
	else cnt_val_rdy <= sdo_ser_rdy_d & sck_cnt_sub[6:0]==127; 

initial begin
 	cnt = 0;
 	cnt_val = 0;
 	cnt_val_rdy = 0;
	sdo_ser_rdy_d = 0;
end
endmodule
