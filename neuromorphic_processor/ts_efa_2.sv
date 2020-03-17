`timescale 1ns / 1ps
module ts_efa_B #(parameter SCAL_ADDR_LEN=8, TEMP_ADDR_LEN=8) 
	(input logic clk, reset,
	 input logic ts_efa_out_en,
	 input logic sel,
	 input logic [T_FIX_WID-1:0] t_fix_reg,
	 output logic [T_FIX_WID-1:0] ts_efa_b_out);					// exponential function val

localparam T_FIX_WID = TEMP_ADDR_LEN+SCAL_ADDR_LEN;				// exp fun val width

logic [T_FIX_WID-1:0] temp_lut[2**SCAL_ADDR_LEN-1:0];				// template LUT
logic [T_FIX_WID-1:0] scal_lut[2**TEMP_ADDR_LEN-1:0];				// scaling LUT
logic [SCAL_ADDR_LEN-1:0] scal_addr;							// scaling LUT address
logic [TEMP_ADDR_LEN-1:0] temp_addr;							// template LUT address
logic [T_FIX_WID-1:0] scal_val, temp_val;
(*use_dsp = "yes"*) logic [2*(T_FIX_WID-1):0] result_upsc, result;	

// initializing LUTs from memory files
initial begin
	$readmemb("C:/Users/KJS/VIVADO_WS/fpga_projects/neuromorphic_processor/template_lut_15_2_e_100x.mem", temp_lut);
	$readmemb("C:/Users/KJS/VIVADO_WS/fpga_projects/neuromorphic_processor/scaling_lut_15_2_e_100x.mem", scal_lut);
end

assign scal_addr = t_fix_reg[T_FIX_WID-1:SCAL_ADDR_LEN];
assign temp_addr = t_fix_reg[TEMP_ADDR_LEN-1:0]; 

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
		result_upsc <= 0;
		result 		<= 0;
	end
	else begin
		result_upsc <= scal_val*temp_val;
		result <= result_upsc>>T_FIX_WID-1;
	end

assign ts_efa_b_out = (ts_efa_out_en) ? result : 0;

initial begin
	scal_val = '0;
	temp_val = '0;
	result = '0;
	result_upsc = '0;
end
endmodule