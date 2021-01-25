`timescale 1ns / 1ps
module holdb_gen #(parameter CLK_SCK_SCAL=40, HOLD_CYC=16) 
	(input logic clk, reset, comm_pause,
	 output logic holdb);

localparam HOLD_PER = CLK_SCK_SCAL*HOLD_CYC;

logic [$clog2(HOLD_PER)-1:0] holdb_cnt;

always @(posedge clk)
	if (reset) holdb_cnt <= 0;
	else if (comm_pause) holdb_cnt <= 0;
	else holdb_cnt <= (holdb_cnt==HOLD_PER-1) ? holdb_cnt : holdb_cnt + 1;

always @(posedge clk)
	if (reset) holdb <= 1;
	else if (comm_pause) holdb <= 0;
	else if (holdb_cnt==HOLD_PER-1) holdb <= 1;  
	else holdb = holdb;

initial begin
	holdb_cnt = HOLD_PER-1;
	holdb = 1;
end
endmodule
