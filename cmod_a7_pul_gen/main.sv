`timescale 1ns / 1ps
module main
	 (input logic sysclk,
      input logic [1:0] btn,    
	  output logic [1:0] led,
	  output logic pio3,
	  output logic pio5, 
	  output logic pio7);

parameter LED_CNT_MAX = 10**6; // 1ms
//parameter PULSE_W = 1000;	   // 10us(target_pulseperiod)/10ns(clk_period)
parameter PULSE_W = 10**6;	   
parameter PULSE_DC = 50;       
parameter PULSE_NO = 5;
parameter NO_ROW = 32;
parameter NO_COL = 32;
parameter SPST_WID = 4;


clk_wiz_0 clk_module (
	.clk_in1(sysclk), 
	.clk_out1(clk));

btn_pulser btn_reset_module (
	.clk(clk),
	.btn_in(btn[0]), 
	.btn_out(reset));

btn_pulser btn_sysen_module (
	.clk(clk), 
	.btn_in(btn[1]), 
	.btn_out(sys_en));

led_control #(.LED_CNT_MAX(LED_CNT_MAX)) led0_module (
	.clk(clk), 
	.reset(reset), 
	.sys_en(sys_en), 
	.led(led[0]));

led_control #(.LED_CNT_MAX(LED_CNT_MAX*10)) led1_module (
	.clk(clk), 
	.reset(reset), 
	.sys_en(sys_en), 
	.led(led[1]));

pulse_gen #(.PULSE_W(PULSE_W),.PULSE_DC(PULSE_DC),.PULSE_NO(PULSE_NO)) pulse1_gen_module (
	.clk(clk), 
	.reset(reset), 
	.sys_en(sys_en), 
	.pulse(pio3));

pulse_gen #(.PULSE_W(PULSE_W*10),.PULSE_DC(PULSE_DC),.PULSE_NO(PULSE_NO)) pulse2_gen_module (
	.clk(clk), 
	.reset(reset), 
	.sys_en(sys_en), 
	.pulse(pio5));

pulse_gen #(.PULSE_W(PULSE_W*100),.PULSE_DC(PULSE_DC),.PULSE_NO(PULSE_NO)) pulse3_gen_module (
	.clk(clk), .reset(reset), .sys_en(sys_en), .pulse(pio7));

logic en;
logic [$clos2(NO_ROW)-1:0] row_sel;
logic [$clos2(NO_COL)-1:0] col_sel;


// device_select #(.NO_ROW(NO_ROW), .NO_COL(NO_COL), .SPST_WID(SPST_WID), .NO_SPST(NO_ROW/SPST_WID)) device_select_module (
// 	.clk(clk), 
// 	.reset(reset), 
// 	.en(en), 
// 	.row_sel(row_sel), 
// 	.col_sel(col_sel));

endmodule
