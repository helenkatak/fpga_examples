`timescale 1ns / 1ps
module main(//input logic USRCLK_P, USRCLK_N,
			input logic reset,
			input logic rx_din,
   			output logic wr_sig,
   			output logic [$clog2(NO_COL)-1:0] wr_col,
   			output logic [$clog2(NO_ROW)-1:0] wr_row);
logic clk;
localparam CLK_PER 	 = 100;   			// 100ns => 10 MHz
localparam WR_WID 	 = 10000; 			// 100000ns = 100us
localparam WR_CLK_NO = WR_WID/CLK_PER;	
localparam NO_ROW 	 = 256;
localparam NO_COL	 = 128;

logic [$clog2(NO_ROW)+$clog2(NO_COL):0] wr_mode_col_row;
logic wr_en;

// input command //
always @(posedge clk) 
	if (reset) wr_en <= 0;
	else wr_en <= rx_din;

wr_mode #(.WR_CLK_NO(WR_CLK_NO), .NO_ROW(NO_ROW), .NO_COL(NO_COL))
	wr_mode_module (
	.clk(clk), .reset(reset), 
	.wr_en(wr_en), .wr_mode_col_row(wr_mode_col_row), 	// module input
	.wr_sig(wr_sig), .wr_mode(wr_md), 
	.wr_col(wr_col), .wr_row(wr_row));					// module output 

rd_mode #()
	rd_mode_module (
	.clk(clk), .reset(reset),
	.rd_en()

		);
initial begin
	wr_en = 0;
	wr_mode_col_row = 0;
end
endmodule
