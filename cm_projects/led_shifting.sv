`timescale 1ns / 1ps
module led_shifting
	(input logic usrclk_p, usrclk_n,
	 input logic reset,
	 output logic [7:0] led);

clk_wiz_0 clk_module(
	.clk_in1_p(usrclk_p),
	.clk_in1_n(usrclk_n),
	.clk_out1(clk));

localparam CYC_NO = 10000000;        		//  every 100 ms 

logic [$clog2(CYC_NO)-1:0] count; 			// 100 ms counter
logic count_end;							// goes high every 100 ms
logic [2:0] led_reg;                		// LED register

assign count_end = (count== CYC_NO);

//counter
always @(posedge clk)
    if (reset) count <= 0;
    else if (~count_end) count <= count +1;
    else if (count_end) count <= 0;
   
//led_reg
always @(posedge clk)   
    if (reset) led_reg <= 0;
    else if (count_end) led_reg <= led_reg +1;   

//led blink
always @(posedge clk)
    if (reset) led <= 8'd1;
    else if (count_end & led == 8'b10000000) led <= led >> 7;  
    else if (count_end ) led <= led << 1;     

initial begin
count = '0;
led_reg = '0;
led = '0;
end
endmodule



// ---------------------------- Kate's code below---------------------------
//logic [$clog2(CYC_NO)-1:0] count;					// Maximum size of count
//logic count_end_flag;
//logic [7:0] led_reg;

//clk_wiz_0 clk_module(
//	.clk_in1_p(usrclk_p),
//	.clk_in1_n(usrclk_n),
//	.clk_out1(clk));

//assign count_end_flag = (count == CYC_NO);

//always @(posedge clk) 	// at every positive clock
//	if (reset) count <= 24'hffffff;
//	else if (~count_end_flag) count <= count + 1; 
//	else if (count_end_flag) count <= 0;

//always @(posedge clk)
//	if (reset) led_reg <= 0;
//	else if (count==24'hffffff) begin
//			led_reg <= 0;
//			led_reg[0] <= 1;
//		end
//	else if (count_end_flag) led_reg <= led_reg << 1;

//assign led = led_reg;

//initial begin
//	count = 0;
//	led_reg = '0;
//end
//endmodule
