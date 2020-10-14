`timescale 1ns / 1ps
module main
	 (//input logic sysclk,
      input logic [1:0] btn,   
	  output logic [1:0] led,
	  output logic pio3,
	  output logic pio5, 
	  output logic pio7
	 );

parameter LED_CNT_MAX = 10**6; // 1ms
//parameter PULSE_W = 1000;	   // 10us(target_pulseperiod)/10ns(clk_period)
parameter PULSE_W = 10**6;	   
parameter PULSE_DC = 50;       
parameter PULSE_NO = 5;
parameter NO_ROW = 32;
parameter NO_COL = 32;
parameter SW_WID = 4;

logic clk;
logic en;
logic device_config;
logic [$clog2(NO_ROW)-1:0] row_sel;
logic [$clog2(NO_COL)-1:0] col_sel;

//clk_wiz_0 clk_module (.clk_in1(sysclk), .clk_out1(clk));

btn_pulser btn_reset_module (
	.clk(clk), .btn_in(btn[0]), .btn_out(reset));

btn_pulser btn_sysen_module (
	.clk(clk), .btn_in(btn[1]), .btn_out(sys_en));

led_control #(.LED_CNT_MAX(LED_CNT_MAX)) led0_module (
	.clk(clk), .reset(reset), .sys_en(sys_en), .led(led[0]));

led_control #(.LED_CNT_MAX(LED_CNT_MAX*10)) led1_module (
	.clk(clk), .reset(reset), .sys_en(sys_en), .led(led[1]));

pulse_gen #(.PULSE_W(PULSE_W),.PULSE_DC(PULSE_DC),.PULSE_NO(PULSE_NO)) pulse1_gen_module (
	.clk(clk), .reset(reset), .sys_en(sys_en), .pulse(pio3));

pulse_gen #(.PULSE_W(PULSE_W*10),.PULSE_DC(PULSE_DC),.PULSE_NO(PULSE_NO)) pulse2_gen_module (
	.clk(clk), .reset(reset), .sys_en(sys_en), .pulse(pio5));

pulse_gen #(.PULSE_W(PULSE_W*100),.PULSE_DC(PULSE_DC),.PULSE_NO(PULSE_NO)) pulse3_gen_module (
	.clk(clk), .reset(reset), .sys_en(sys_en), .pulse(pio7));

row_select #(.NO_ROW(NO_ROW),  
			 .SW_WID(SW_WID), 
			 .NO_SW(NO_ROW/SW_WID)) row_select_module(
			 .clk(clk), 
			 .reset(reset), 
			 .en(en), 
			 .device_config(device_config),
			 .row_sel(row_sel),
			 .row_sw(row_sw),
			 .row_swb(row_swb));

col_select #(.NO_COL(NO_COL),  
			 .SW_WID(SW_WID), 
			 .NO_SW(NO_COL/SW_WID)) col_select_module(
			 .clk(clk), 
			 .reset(reset), 
			 .en(en), 
			 .device_config(device_config),
			 .col_sel(col_sel),
			 .col_sw(col_sw),
			 .col_swb(col_swb));

logic conn_mode;
logic [2:0] op_mode;

mode_select mode_select_module(
	.clk(clk),
	.reset(reset),
	.en(en),
	.conn_mode(conn_mode), 	// FPGA or SMU connection modes
	.op_mode(op_mode)		// SET, RESET or READ modes
	); 

initial begin
	row_sel = 0;
	col_sel = 0;
end

endmodule
