`timescale 1ns / 1ps
module ts_efa #(parameter SCAL_ADDR_LEN=8, TEMP_ADDR_LEN=8, NEURON_NO=2**8) 
	(input logic clk, reset,
	 input logic ts_efa_en, t_fix_wr_en,
	 input logic [$clog2(NEURON_NO)-1:0] t_fix_wr_addr,
	 input logic sp_in, sp_out,
	 output logic [T_FIX_WID-1:0] ts_efa_out);					// exponential function val

localparam T_FIX_WID = TEMP_ADDR_LEN+SCAL_ADDR_LEN;				// exp fun val width

logic [T_FIX_WID-1:0] t_fix_ram [NEURON_NO-1:0];		 			// time fix ram	
logic [T_FIX_WID-1:0] t_fix_reg;	
logic [T_FIX_WID-1:0] temp_lut[2**SCAL_ADDR_LEN-1:0];				// template LUT
logic [T_FIX_WID-1:0] scal_lut[2**TEMP_ADDR_LEN-1:0];				// scaling LUT
logic [SCAL_ADDR_LEN-1:0] scal_addr;							// scaling LUT address
logic [TEMP_ADDR_LEN-1:0] temp_addr;							// template LUT address
logic [T_FIX_WID-1:0] scal_val, temp_val;
(*use_dsp = "yes"*) logic [2*(T_FIX_WID-1):0] result_upsc;
(*use_dsp = "yes"*) logic [T_FIX_WID-1:0] result;	

// time stamping for EFA module information
always @(posedge clk)
	if (t_fix_wr_en) t_fix_ram[t_fix_wr_addr] <= (sp_out) ? 0 : ((sp_in) ? 1 : t_fix_ram[t_fix_wr_addr]+1);

assign t_fix_reg = (sp_in) ? 0 : t_fix_ram[t_fix_wr_addr]; 		// time_fix value

// initializing LUTs from memory files
initial begin
	$readmemb("C:/Users/KJS/VIVADO_WS/fpga_projects/neuromorphic_processor/temp_lut.mem", temp_lut);
	$readmemb("C:/Users/KJS/VIVADO_WS/fpga_projects/neuromorphic_processor/scal_lut.mem", scal_lut);
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

assign ts_efa_out = (ts_efa_en) ? result : 0;

initial begin
	for (int i=0; i<2**T_FIX_WID; i++) 
		t_fix_ram[i] = 0;
	scal_val = '0;
	temp_val = '0;
	result = '0;
	result_upsc = '0;
end
endmodule
