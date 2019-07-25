`timescale 1ns / 1ps
module counter
	(input logic clk, reset,
	 output logic led);

localparam CYCLE_NO = 10000000;  // Number of cycles for led on/off

logic [31:0] count;
logic count_end;

assign count_end = (count == CYCLE_NO-1);

always @(posedge clk, posedge reset)
	if (reset) count <= 0;
	else count <= count_end ? 0 : count + 1; 

always @(posedge clk, posedge reset)
	if (reset) led <= 0;
	else if (count_end) led <= ~led;

initial begin
	count = 0;
	led = 0;
end

endmodule
