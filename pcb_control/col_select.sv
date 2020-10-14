`timescale 1ns / 1ps
module col_select #(parameter NO_COL=32, SW_WID=4, NO_SW=NO_COL/SW_WID)
	(input logic clk, reset,
	 input logic en,
	 input logic device_config,
	 input logic [$clog2(NO_COL)-1:0] col_sel,
	 output logic [NO_COL-1:0] col_sw, col_swb
    );

logic [NO_COL-1:0] col_sw, col_swb;

// if col_sel <- 0, col_sw[0] <- 1
// if col_sel <- 31, col_sw[31] <- 1

always @(posedge clk)
	if (reset) begin
		col_sw <= 0;
		col_swb <= 1;
	end
	else if (device_config) begin
		col_sw[col_sel] <= ~col_sw[col_sel];
		col_swb[col_sel] <= ~col_swb[col_sel];
	end

initial begin
	col_sw = 0;
	col_swb = 32'hffffffff;
end
endmodule
