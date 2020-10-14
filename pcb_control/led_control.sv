`timescale 1ns / 1ps
module led_control #(parameter LED_CNT_MAX = 10**7)
	(input logic clk, reset,
	 input logic sys_en,
	 output logic led);

logic cnt_on, led_state;
logic [$clog2(LED_CNT_MAX)-1:0] cnt;

always @(posedge clk)
	if (reset) cnt_on <= 0;
	else if (sys_en) cnt_on <= 1;

always @(posedge clk)
	if (reset) cnt <= 0;
	else if (cnt == LED_CNT_MAX) cnt <= 0;
	else if (cnt_on) cnt <= cnt + 1;  

always @(posedge clk)
	if (reset) led_state <= 0;
	else if (cnt == LED_CNT_MAX) led_state <= ~led_state;

assign led = led_state;

initial begin
	cnt_on = 0;	
	cnt = 0;
	led_state = 0;
end
endmodule
