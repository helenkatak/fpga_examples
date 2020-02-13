`timescale 1ns / 1ps
module dt_counter #(parameter DT=1000, TS_WIDTH=16)
	(input logic clk, reset, sys_en,
	 output logic [$clog2(DT)-1:0] dt_count,		// dt counts clock
	 output logic dt_tick,							// dt enable signals
	 output logic [TS_WIDTH-1:0] dt_ts);			// time stamp														

logic dt_en;												
// dT counter activates dt.tick every 1 ms 
assign dt_tick = (dt_count == DT-1);

always @(posedge clk)							
	if (reset) dt_en <= 0;				
	else if (sys_en) dt_en <= 1'b1;
			
always @(posedge clk)
	if (reset) dt_count <= 0;
	else if (dt_en) dt_count <= (dt_tick) ? 0 : dt_count + 1'b1;

always @(posedge clk)
	if (reset) dt_ts <= '0; 						// time stamping spiking information
	else if (dt_tick) dt_ts <= dt_ts + 1'b1;

initial begin
	dt_en = 0;
	dt_count = '0;
	dt_ts = '0;
end
endmodule
