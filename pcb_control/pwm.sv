`timescale 1ns / 1ps
module pulse_gen #(parameter PULSE_W=8, PULSE_DC=50, PULSE_NO=2)
	(input logic clk, reset, sys_en,
	 output logic pulse);


logic cnt_on;
logic [$clog2(PULSE_NO):0] pulse_cnt;
logic [$clog2(PULSE_W)-1:0] cnt;

always @(posedge clk)
	if (reset) cnt_on <= 0;
	else if (sys_en) cnt_on <= 1;
	else if (pulse_cnt==PULSE_NO) cnt_on <= 0;

always @(posedge clk)
	if (reset) cnt <= 0;
	else if (cnt_on) cnt <= cnt + 1;
	else if (pulse_cnt==PULSE_NO) cnt <= 0;

always @(posedge clk)
	if (reset) pulse_cnt <= 0;
	else if (cnt == PULSE_W-1) pulse_cnt <= pulse_cnt + 1;
	else if (sys_en) pulse_cnt <= 0;

always @(posedge clk) 
	if (reset) pulse <= 0;
	else if (cnt_on) pulse <= (cnt>0 & cnt<=PULSE_W*PULSE_DC/100);
	else pulse <= 0;

initial begin
	cnt_on = 0;
	pulse_cnt = 0;
	cnt = 0;
	pulse = 0;
end
endmodule
