`timescale 1ns / 1ps
module row_select #(parameter NO_ROW=32, SW_WID=4, NO_SW=NO_ROW/SW_WID)
	(input logic clk, reset,
	 input logic en,
	 input logic device_config,
	 input logic [$clog2(NO_ROW)-1:0] row_sel,
	 output logic [NO_ROW-1:0] row_sw, row_swb
    );

logic [NO_ROW-1:0] row_sw, row_swb;

// if row_sel <- 0, row_sw[0] <- 1
// if row_sel <- 31, row_sw[31] <- 1

always @(posedge clk)
	if (reset) begin
		row_sw <= 0;
		row_swb <= 1;
	end
	else if (device_config) begin
		row_sw[row_sel] <= ~row_sw[row_sel];
		row_swb[row_sel] <= ~row_swb[row_sel];
	end

initial begin
	row_sw = 0;
	row_swb = 32'hffffffff;
end
endmodule
