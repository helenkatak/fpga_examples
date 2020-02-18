`timescale 1ns / 1ps
module int_signal #(parameter NEURON_NO=2**8)
	(input logic 	clk, reset, sys_en,
	 input logic 	[1:0] ext_req,
	 input logic  	dt_tick,
	 output logic 	t_fix_wr_en,
	 output logic 	[$clog2(NEURON_NO)-1:0] t_fix_wr_addr,
	 output logic 	update_en,
	 output logic 	ref_wr_en,
	 output logic 	[$clog2(NEURON_NO)-1:0] ref_wr_addr,
	 output logic 	[$clog2(NEURON_NO)-1:0] ampl_wr_addr,
	 output logic 	[$clog2(NEURON_NO)-1:0] sp_out_wr_addr);

logic [$clog2(NEURON_NO)-1:0] int_rd_addr, int_rd_addr_d, int_rd_addr_dd, int_rd_addr_ddd;
logic int_rd_en, int_rd_en_d, int_rd_en_dd;
logic [$clog2(NEURON_NO)-1:0] int_wr_addr_d, int_wr_addr_dd;
logic update_en_d, update_en_dd;

always @(posedge clk)
	if (reset) int_rd_addr <= '0;
	else if (ext_req) int_rd_addr <= int_rd_addr;
	else if (~dt_tick)  int_rd_addr <= (int_rd_addr==NEURON_NO-1) ? int_rd_addr : int_rd_addr + 1'b1;
	else int_rd_addr <= int_rd_addr + 1'b1;

always @(posedge clk) begin
	int_rd_addr_d 	<= int_rd_addr;
	int_rd_addr_dd 	<= int_rd_addr_d;
	ampl_wr_addr	<= int_rd_addr_dd; 		// amplitute update addr for spike_in
	int_wr_addr_d	<= ampl_wr_addr; 		// refractory reading address
	int_wr_addr_dd 	<= int_wr_addr_d;
	ref_wr_addr 	<= int_wr_addr_dd;  	// refractory writing address			 							
end

assign t_fix_wr_addr = int_rd_addr;			// t_fix writing address
assign sp_out_wr_addr = int_wr_addr_dd;		// spike out writing address

always @(posedge clk)
	if (reset) int_rd_en <= 0;
	else if (dt_tick) int_rd_en 	<= (~ext_req) ? 1'b1 : 0;
	else if (~ext_req) int_rd_en 	<= (int_rd_addr==NEURON_NO-1) ? 0 : int_rd_en; 

always @(posedge clk) begin
	int_rd_en_d 	<= int_rd_en;
	int_rd_en_dd 	<= int_rd_en_d;
	update_en 		<= int_rd_en_dd;  		// ts_efa_en, srm_en and ampl_wr_en
	update_en_d 	<= update_en;			// amplitute enable
	update_en_dd 	<= update_en_d;
	ref_wr_en		<= update_en_dd; 			// refrectory write enable		
end

assign t_fix_wr_en = int_rd_en;				// t_fix writing enable

initial begin
	int_rd_addr = NEURON_NO-1;
	int_rd_addr_d = NEURON_NO-1;
	int_rd_addr_dd = NEURON_NO-1;
	int_rd_addr_ddd = NEURON_NO-1;
	int_wr_addr_d = NEURON_NO-1;
	int_wr_addr_dd = NEURON_NO-1;
	ref_wr_addr = NEURON_NO-1;
	ampl_wr_addr = NEURON_NO-1;
	int_rd_en = 0;
	int_rd_en_d = '0;
	int_rd_en_dd = '0;

	update_en = '0;	
	update_en_d = '0;
	update_en_dd = '0;

	ref_wr_en = '0;
end
endmodule
