`timescale 1ns / 1ps
module bit_count #(parameter OP_CYC=16, SER_LEN=8, SER_ADDR=64, MEM_TOT=32768)
	(input logic clk, reset,
	 input logic [SER_LEN-1:0] inst, dummy,
	 input logic sdo_ser, sdo_ser_rdy, 
	 input logic [$clog2(OP_CYC*(3+SER_ADDR))-1:0] sck_cnt,
	 input logic [$clog2(MEM_TOT/SER_ADDR)-1:0] row_cnt,
	 output logic [SER_LEN-1:0] cnt_val_out,
	 output logic cnt_val_rdy_out);

logic sdo_ser_rdy_d, cnt_val_rdy, cnt_val_rdy_d, cnt_val_rdy_2d;
logic [$clog2(SER_ADDR*SER_LEN):0] cnt, sck_cnt_sub, cnt_val;

localparam NOR_CNT = 2**$clog2(16*SER_LEN)-1;
localparam FAST_CNT = 2**$clog2(SER_ADDR*SER_LEN)-1;

assign sck_cnt_sub = (inst==11) ? (row_cnt==0 ? (sck_cnt>=4*SER_LEN ? sck_cnt-4*SER_LEN : 0) : sck_cnt ) : (sck_cnt>=3*SER_LEN ? sck_cnt-3*SER_LEN : 0);

always @(posedge clk) sdo_ser_rdy_d <= sdo_ser_rdy;

(*ram_style = "distributed"*) logic [SER_LEN*SER_ADDR-1:0] input_lut[2**SER_LEN-1:0];	
initial $readmemb("C:/Users/KJS/PROJECT_WS/fpga_projects/rm25c256ds_control/input.mem", input_lut);
//initial $readmemb("C:/Users/427/Desktop/rm25c256ds_control/input.mem", input_lut);

logic [SER_LEN*SER_ADDR-1:0] x;
assign x = (sck_cnt_sub==1055) ? 0 : input_lut[dummy][sck_cnt_sub];

logic [$clog2(SER_LEN*SER_ADDR)-1:0] pcnt;
logic tx_rdy_multi;

always @(posedge clk)
	if (reset) cnt <= 0;
	else if (sdo_ser_rdy) begin
		if (inst==11) cnt <= (x==0) ? (sdo_ser==0 ? cnt+1 : cnt ) : cnt + sdo_ser;
		else if (inst==34) cnt <= cnt+sdo_ser;
	end
	else if (sdo_ser_rdy_d) begin
		if (inst==11) cnt <= sck_cnt_sub[$clog2(SER_ADDR*SER_LEN):0]==FAST_CNT ? 0 : cnt;
		else if (inst==34) cnt <= sck_cnt_sub[$clog2(16*SER_LEN)-1:0]==NOR_CNT ? 0 : cnt;
	end
	else if (cnt_val_rdy) cnt <= 0;

always @(posedge clk) 
	if (reset) cnt_val <= 0;
	else if (inst==11) cnt_val <= sdo_ser_rdy_d&sck_cnt_sub[$clog2(SER_ADDR*SER_LEN)-1:0]==FAST_CNT ? cnt : cnt_val;
	else cnt_val <= sdo_ser_rdy_d&sck_cnt_sub[$clog2(16*SER_LEN)-1:0]==NOR_CNT ? cnt : cnt_val;

assign cnt_val_out = (inst==11) ? (cnt_val_rdy ? cnt_val[SER_LEN-1:0] : cnt_val>>8) : cnt_val[SER_LEN-1:0];	

always @(posedge clk)
	if (reset) cnt_val_rdy <= 0;
	else if (inst==11) cnt_val_rdy <= sdo_ser_rdy_d & (sck_cnt_sub[$clog2(SER_ADDR*SER_LEN)-1:0]==FAST_CNT); 
	else cnt_val_rdy <= sdo_ser_rdy_d & (sck_cnt_sub[$clog2(16*SER_LEN)-1:0]==NOR_CNT); 

always @(posedge clk) begin
	cnt_val_rdy_d <= cnt_val_rdy;
	cnt_val_rdy_2d <= cnt_val_rdy_d;
end

assign cnt_val_rdy_out = (inst==11) ? cnt_val_rdy|cnt_val_rdy_2d : cnt_val_rdy;

initial begin
 	cnt = 0;
 	cnt_val = 0;
 	cnt_val_rdy = 0;
 	cnt_val_rdy_d = 0;
 	cnt_val_rdy_2d = 0;
 	sdo_ser_rdy_d = 0;
end
endmodule
