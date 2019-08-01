`timescale 1ns / 1ps
module sw_pulse_detect
	(input logic clk, 
	 input logic [7:0] sw_in,
	 output logic sw_pulse);

logic [7:0] temp1, temp2, sw_temp;


// synchronizer
// always @(posedge clk) begin
// 	sync1 <= sw_in;
// 	sync2 <= sync1;
// end

// pulser
always @(posedge clk) temp1 <= sw_in;
always @(posedge clk) temp2 <= temp1;

assign sw_temp = (temp1 ^ temp2);

assign sw_pulse = sw_temp[0]|sw_temp[1]|sw_temp[2]|sw_temp[3]|sw_temp[4]|sw_temp[5]|sw_temp[6]|sw_temp[7];

endmodule
