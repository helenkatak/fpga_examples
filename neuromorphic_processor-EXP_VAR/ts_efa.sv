`timescale 1ns / 1ps
module ts_efa_var #(parameter SCAL_ADDR_LEN=8, TEMP_ADDR_LEN=8, TAU_VAR_WID=12, 
							  RECI_ADDR_LEN = 6, TAU_TH = 39, TAU_S = 9) 
	(input logic 	clk, reset,
	 input logic 	we, 
	 input logic 	re,
	 input logic 	[T_VAR_WID/2-1:0] ext_wr_addr,
	 input logic 	[T_VAR_WID-1:0] ext_din, 
	 input logic 	re_reci,
	 input logic 	[1:0] tsefa_cnt,
	 input logic 	[T_VAR_WID-1:0] t_var_thr_reg,
	 output logic 	[T_FIX_WID-1:0] ts_efa_out);

localparam T_FIX_WID = TEMP_ADDR_LEN+SCAL_ADDR_LEN;		// exp fun val width
localparam T_VAR_WID =12;

(*ram_style = "distributed"*) logic [TAU_VAR_WID-1:0] reci_lut[2**RECI_ADDR_LEN-1:0];			// reciprical LUT
logic [T_FIX_WID-1:0] temp_lut[2**SCAL_ADDR_LEN-1:0];	// template LUT
logic [T_FIX_WID-1:0] scal_lut[2**TEMP_ADDR_LEN-1:0];	// scaling LUT
logic [RECI_ADDR_LEN-1:0] reci_addr;					// reciprocal LUT address
logic [SCAL_ADDR_LEN-1:0] scal_addr;					// scaling LUT address
logic [TEMP_ADDR_LEN-1:0] temp_addr;					// template LUT address
logic [1:0] addr_cnt_d;
logic [RECI_ADDR_LEN-1:0] tau_var_reg;
logic [TAU_VAR_WID-1:0] reci_val, reci_val_d;
(* use_dsp = "yes" *) logic [3*T_VAR_WID-1:0] t_var_downsc, t_var_result;
logic [T_VAR_WID-1:0] t_var_reg_d, t_var_reg_2d;
logic [T_FIX_WID-1:0] t_fix_reg;
logic re_fix_m, re_fix_s, re_fix_th;
logic [T_FIX_WID-1:0] scal_val, temp_val, scal_val_d, temp_val_d;
(* use_dsp = "yes" *) logic [2*T_FIX_WID-1:0] result_upsc, result;	

// initializing LUTs from memory files
initial begin
	$readmemb("C:/Users/KJS/VIVADO_WS/fpga_projects/neuromorphic_processor/rec_lut.mem", reci_lut);
	$readmemb("C:/Users/KJS/VIVADO_WS/fpga_projects/neuromorphic_processor/temp_lut.mem", temp_lut);
	$readmemb("C:/Users/KJS/VIVADO_WS/fpga_projects/neuromorphic_processor/scal_lut.mem", scal_lut);
end

// Externel writing of SCAL_RAM and TEMP_RAM
always @(posedge clk)
	if (we) reci_lut[ext_wr_addr] <= ext_din;

// Internal process
always @(posedge clk) addr_cnt_d <= tsefa_cnt;

assign tau_var_reg =  (re_reci) ? ((tsefa_cnt== 3) ? TAU_S : TAU_TH) : 0;

assign reci_addr = tau_var_reg;

always @(posedge clk)
	if (reset) reci_val <= 0;
	else reci_val <= reci_lut[reci_addr];

always @(posedge clk) reci_val_d <= reci_val;

always @(posedge clk) begin
	t_var_reg_d <= t_var_thr_reg;
	t_var_reg_2d <= t_var_reg_d;
end

always @(posedge clk)
	if (reset) begin
		t_var_downsc <= 0;
		t_var_result <= 0;
	end
	else begin 
		t_var_downsc <= t_var_reg_2d*reci_val_d;
		t_var_result <= t_var_downsc << T_VAR_WID;
	end

assign t_fix_reg = (t_var_result==0) ? 0 : ((t_var_result[3*T_VAR_WID-1:T_VAR_WID] > 2**16-1) ? 2**16-1 : t_var_result[3*T_VAR_WID-8-1:T_VAR_WID]);

always @(posedge clk)
	if (reset) re_fix_m <= 0;
	else if (addr_cnt_d == 3) re_fix_m <= 1;
	else re_fix_m <= 0;

always @(posedge clk) begin
	re_fix_s <= re_fix_m;
	re_fix_th <= re_fix_s;
end

assign scal_addr = (re_fix_m | re_fix_s | re_fix_th) ? t_fix_reg[T_FIX_WID-1:SCAL_ADDR_LEN] : 0;
assign temp_addr = (re_fix_m | re_fix_s | re_fix_th) ? t_fix_reg[TEMP_ADDR_LEN-1:0] : 0; 

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
		result_upsc <= scal_val_d*temp_val_d;
		result 		<= result_upsc>>T_FIX_WID-1;
	end

assign ts_efa_out = (re) ? result : 0;

initial begin
	addr_cnt_d	= '0;
	re_fix_m 	= '0;
	re_fix_s 	= '0;
	re_fix_th 	= '0;
	reci_val  	= '0;
	reci_val_d 	= '0;
	t_var_downsc= '0;
	t_var_result= '0;
	t_var_reg_d = '0;
	t_var_reg_2d= '0;
	scal_val 	= '0;
	scal_val_d 	= '0;
	temp_val 	= '0;
	temp_val_d 	= '0;
	result 		= '0;
	result_upsc = '0;
end
endmodule
