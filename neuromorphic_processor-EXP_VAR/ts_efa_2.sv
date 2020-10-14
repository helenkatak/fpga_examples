`timescale 1ns / 1ps
module ts_efa_B #(parameter SCAL_ADDR_LEN=8, TEMP_ADDR_LEN=8) 
	(input logic 	clk, reset,
	 input logic 	we, 
	 input logic 	[5:0] ram_sel,
	 input logic 	[T_FIX_WID/2-1:0] ext_wr_addr,
	 input logic 	[T_FIX_WID-1:0] ext_din, 
	 input logic 	re,
	 input logic 	[T_FIX_WID-1:0] t_fix_reg,
	 output logic 	[T_FIX_WID-1:0] ts_efa_b_out);					// exponential function val

localparam T_FIX_WID = TEMP_ADDR_LEN+SCAL_ADDR_LEN;				// exp fun val width

(*ram_style = "distributed"*) logic [T_FIX_WID-1:0] temp_lut[2**SCAL_ADDR_LEN-1:0];				// template LUT
(*ram_style = "distributed"*) logic [T_FIX_WID-1:0] scal_lut[2**TEMP_ADDR_LEN-1:0];				// scaling LUT
logic [SCAL_ADDR_LEN-1:0] scal_addr;							// scaling LUT address
logic [TEMP_ADDR_LEN-1:0] temp_addr;							// template LUT address
logic [T_FIX_WID-1:0] scal_val, temp_val, scal_val_d, temp_val_d;
(*use_dsp = "yes"*) logic [2*(T_FIX_WID-1):0] result_upsc, result;	
(*use_dsp = "yes"*) logic [T_FIX_WID-1:0] ts_efa_b_out;
// initializing LUTs from memory files
initial begin
	$readmemb("C:/Users/KJS/VIVADO_WS/fpga_projects/neuromorphic_processor/template_lut_15_2_e_100x.mem", temp_lut);
	$readmemb("C:/Users/KJS/VIVADO_WS/fpga_projects/neuromorphic_processor/scaling_lut_15_2_e_100x.mem", scal_lut);
end

// Externel writing of THR_SCAL_RAM and THR_TEMP_RAM
always @(posedge clk)
	if (we & (ram_sel==4)) scal_lut[ext_wr_addr] <= ext_din;
	else if (we & ram_sel==5) temp_lut[ext_wr_addr] <= ext_din;

assign scal_addr = (re) ? t_fix_reg[T_FIX_WID-1:SCAL_ADDR_LEN] : 0;
assign temp_addr = (re) ? t_fix_reg[TEMP_ADDR_LEN-1:0] : 0; 

always @(posedge clk)
	if (reset) begin
		scal_val <= 0;
		temp_val <= 0;
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
		result_upsc <= scal_val_d*temp_val_d;
		result <= result_upsc>>T_FIX_WID-1;
	end

assign ts_efa_b_out = result;

initial begin
	scal_val = '0;
	temp_val = '0;
	scal_val_d = '0;
	temp_val_d = '0;
	result = '0;
	result_upsc = '0;
end
endmodule