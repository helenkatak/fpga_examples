`timescale 1ns / 1ps
module ts_efa_A #(parameter SCAL_ADDR_LEN=8, TEMP_ADDR_LEN=8) 
	(input logic clk, reset,
	 input logic 	we, 
	 input logic 	[5:0] ram_sel,
	 input logic 	[T_FIX_WID/2-1:0] ext_wr_addr,
	 input logic 	[T_FIX_WID-1:0] ext_din, 
	 input logic 	re,
	 input logic 	[T_FIX_WID-1:0] t_fix_reg,
	 output logic 	[T_FIX_WID-1:0] ts_efa_a_out);				// exponential function val
	 // input logic [T_FIX_WID-1:0] t_thr_reg,					// extra input for threshold
	 // output logic [T_FIX_WID-1:0] thr_ts_efa_out);			// extra output for threshold

localparam T_FIX_WID = TEMP_ADDR_LEN+SCAL_ADDR_LEN;				// exp fun val width

(*ram_style = "distributed"*) logic [T_FIX_WID-1:0] temp_lut[2**SCAL_ADDR_LEN-1:0];		// template LUT
(*ram_style = "distributed"*) logic [T_FIX_WID-1:0] scal_lut[2**TEMP_ADDR_LEN-1:0];		// scaling LUT
logic [SCAL_ADDR_LEN-1:0] scal_addr;							// scaling LUT address
logic [TEMP_ADDR_LEN-1:0] temp_addr;							// template LUT address
logic [T_FIX_WID-1:0] scal_val, temp_val, scal_val_d, temp_val_d;
(* use_dsp = "yes" *) logic [2*(T_FIX_WID-1):0] result_upsc, result;	

// initializing LUTs from memory files
initial begin
	$readmemb("C:/Users/KJS/VIVADO_WS/fpga_projects/neuromorphic_processor/temp_lut.mem", temp_lut);
	$readmemb("C:/Users/KJS/VIVADO_WS/fpga_projects/neuromorphic_processor/scal_lut.mem", scal_lut);
end

// Externel writing of SCAL_RAM and TEMP_RAM
always @(posedge clk)
	if (we & (ram_sel==0)) scal_lut[ext_wr_addr] <= ext_din;
	else if (we & ram_sel==1) temp_lut[ext_wr_addr] <= ext_din;

// Internal process
assign scal_addr = (re) ? t_fix_reg[T_FIX_WID-1:SCAL_ADDR_LEN] : 0;
assign temp_addr = (re) ? t_fix_reg[TEMP_ADDR_LEN-1:0] : 0; 

always @(posedge clk)
	if (reset) begin
		temp_val <= 0;
		scal_val <= 0;
	end
	else begin 
		scal_val <= scal_lut[scal_addr];
		temp_val <= temp_lut[temp_addr];
	end

always @(posedge clk)
	if (reset) begin
		scal_val_d <= 0;
		temp_val_d <= 0;
	end
	else begin
		scal_val_d <= scal_val; 
		temp_val_d <= temp_val;
	end

always @(posedge clk)
	if (reset) begin
		result_upsc <= 0;
		result 		<= 0;
	end
	else begin
		result_upsc <= scal_val*temp_val;
		result 		<= result_upsc>>T_FIX_WID-1;
	end

assign ts_efa_a_out = result;

initial begin
	scal_val = '0;
	scal_val_d 	= '0;
	temp_val = '0;
	temp_val_d 	= '0;
	result = '0;
	result_upsc = '0;			
end
endmodule
