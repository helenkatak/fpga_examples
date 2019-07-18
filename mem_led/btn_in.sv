`timescale 1ns / 1ps
module btn_in
	(input logic clk, btn_in,
	 output logic btn_out);

localparam HOLD = 1;

logic sync1, sync2;
logic temp;
logic btn_pulse;
logic [31:0] count;

// synchronizer
always @(posedge clk) begin
	sync1 <= btn_in;
	sync2 <= sync1;
end

// pulser
always @(posedge clk)
	temp <= sync2;
assign btn_pulse = sync2 & ~temp;

// counter for fintering button noise
always @(posedge clk)
	if (btn_pulse) count <= 0;
	else if (count < HOLD) count <= count + 1'b1;

assign btn_out = (count == HOLD-1) & sync2;


// Initialization
initial begin
	sync1 = 0;
	sync2 = 0;
	temp = 0;
	count = 0;
end

endmodule
