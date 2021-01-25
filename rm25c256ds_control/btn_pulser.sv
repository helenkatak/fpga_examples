`timescale 1ns / 1ps
module btn_pulser
	(input logic clk, 
	 input logic btn_in,
	 output logic btn_out);

localparam HOLD = 10**4;

logic sync1, sync2;
logic temp;
logic btn_pulse;
logic [$clog2(HOLD)-1:0] count;


// synchronizer
always @(posedge clk) 
	if (btn_in == 0) sync1 <= btn_in;
	else if (btn_in == 1) sync1 <= btn_in;
	else sync1 <= 0;

// pulser
always @(posedge clk) begin
	sync2 <= sync1;
	temp <= sync2;
end
assign btn_pulse = sync2 & ~temp;

// counter for fintering button noise
always @(posedge clk)
	if (btn_pulse) count <= 0;
	else if (count < HOLD-1) count <= count + 1;

assign btn_out = (count == HOLD-2) & sync2;

// Initialization
initial begin
	sync1 = 0;
	sync2 = 0;
	temp = 0;
	count = HOLD-1;
end
endmodule
