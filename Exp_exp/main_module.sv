`timescale 1ns / 1ps
module main_module
	(input logic USRCLK_N, USRCLK_P, reset,
	 input logic mod_sel,
	 input logic we, sel, re,
	 input logic [wA_BIN-1:0] addr_in,	
	 input logic [wMAX-1:0] data_in,
	 output logic [wMAX-1:0] data_out,
	 output logic [wTOT-1:0] result);

localparam wA_BIN = 6;								// bin LUT address width
localparam wA_IND = 6;								// exp LUT address width
localparam wTOT = wA_BIN + wA_IND;					// logarithm of the total number of points in a fit (x_tot = 2**wTOT)
localparam vMAX = 255;								// max exponent value
localparam wMAX = $clog2(vMAX);						// exp value width

localparam wTn = 6;
localparam wTd = 6;

logic clk;
clk_wiz_0 clock(
	.clk_in1_n(USRCLK_N),
	.clk_in1_p(USRCLK_P),
	.clk_out1(clk));

logic req_var, req_fix;
logic [wTOT-1:0] tn_fix;
logic [wTn-1:0] tn_var;
logic [wTd-1:0] td_var;
logic [wMAX-1:0] result_fix, result_var;

exp_fix #(.wA_BIN(wA_BIN), .wA_IND(wA_IND), .vMAX(vMAX)) fixed_tau_module(
	.clk(clk),
	.reset(reset),
	.req(req_fix),
	.tn(tn_fix),
	.re(re),
	.we(we),
	.sel(sel),
	.addr_in(addr_in),
	.data_in(data_in),
	.data_out(data_out),
	.result_out(result_fix));

exp_rom #(.wTn(wTn), .wTd(wTd)) var_tau_module(
	.clk(clk),
	.reset(reset),
	.req(req_var),
	.tn(tn_var),
	.td(td_var),
	.result_out(result_var));

//module selection: default is fixed_tau_module
always @(posedge clk)
	if (reset) begin 
		req_var <= 0;
		req_fix <= 0;
	end
	else if (~mod_sel) req_fix <= 1;	// "mod_sel = 1" selects fixed_tau_module
	else if (mod_sel) req_var <= 1; 	// "mod_sel = 0" selects fixed_tau_module

always @(posedge clk)
	if (mod_sel) result <= result_var;
	else result <= result_fix;

endmodule
