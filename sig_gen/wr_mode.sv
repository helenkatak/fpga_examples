`timescale 1ns / 1ps
module wr_mode #(parameter WR_CLK_NO=100, NO_ROW=256, NO_COL=128)
	(input logic clk, reset, wr_en,
	 input logic [$clog2(NO_ROW)+$clog2(NO_COL):0] wr_mode_col_row,
	 output logic wr_sig,
	 output logic wr_mode,
	 output logic [$clog2(NO_COL)-1:0] wr_col,
	 output logic [$clog2(NO_ROW)-1:0] wr_row);

logic count_end;
logic [$clog2(WR_CLK_NO)-1:0] count;



assign count_end = (count==WR_CLK_NO);

always @(posedge clk)
	if (reset) count <= 0;
	else if (wr_en) count <= count + 1;
	else if (count != 0) count <= count_end ? 0 : count + 1;

assign wr_sig = (count != 0);

always @(posedge clk) 
	if (reset) begin
		wr_mode <= 0;
		wr_col 	<= 0;
		wr_row 	<= 0;
	end
	else begin
		wr_mode <= (wr_en) ? wr_mode_col_row[$clog2(NO_ROW)+$clog2(NO_COL)] : 0; // SET if 0, RESET if 1
		wr_col 	<= (wr_en) ? wr_mode_col_row[$clog2(NO_ROW)+$clog2(NO_COL)-1:$clog2(NO_ROW)] : 0;
		wr_row 	<= (wr_en) ? wr_mode_col_row[$clog2(NO_ROW)-1:0] : 0;
	end
initial begin
	count = 0;
	wr_mode = 0;
	wr_col = 0;
	wr_row = 0;
end
endmodule
