`timescale 1ns / 1ps
module neuron_module #(parameter NEURON_NO=2**8, TS_WID=12)
	(input logic 	sys_en, clk, 
	 input logic 	reset, 
	 input logic 	[1:0] ext_req,
	 input logic 	[T_FIX_WID/2-1:0] ext_rd_addr, 
	 input logic 	[T_FIX_WID/2-1:0] ext_wr_addr,
	 input logic 	[T_FIX_WID-1:0] ext_din, 
	 output logic 	[T_FIX_WID-1:0] ext_dout,
	 input logic 	en,
	 input logic 	input_spike,
	 input logic 	[TS_WID-1:0] weight_const,
	 input logic	[TS_WID-1:0] dt_ts,
	 input logic	[$clog2(NEURON_NO)-1:0] neuron_addr,
	 input logic 	[1:0] tsefa_cnt,
	 output logic 	[TS_WID+$clog2(NEURON_NO)-1:0] ts_sp_addr,
	 output logic 	sp_out);

localparam UREF = 8;			// FXnum(0.002, FXfamily(12,2))
localparam TAU_M = 163;  		// FXnum(0.04, FXfamily(12,2))
localparam CREF = 204; 			// |uref|/tau_m = 2097/41943 = 0.002/0.04 = 0.05 = FXnum(0.05, FXfamily(12,2))
localparam THR0 = 20;			// FXnum(0.005, FXfamily(12,2))
localparam THR = 409;			// THR0/C_REF = FXnum(0.1, FXfamily(12,2))
localparam NEURON_LEN = 13;																				
localparam MU_WID = TS_WID;
localparam AMPL_WID = TS_WID;
localparam SCAL_ADDR_LEN = 8;
localparam TEMP_ADDR_LEN = 8;
localparam T_FIX_WID = SCAL_ADDR_LEN + TEMP_ADDR_LEN;
localparam T_VAR_WID = 12;
localparam TAU_VAR_WID = 12;
localparam RECI_ADDR_LEN = 6;
localparam TAU_TH = 39;
localparam TAU_S = 9;

logic [T_VAR_WID-1:0] t_var_reg, t_var_reg_d, t_thr_reg, t_reg;
(*ram_style = "distributed"*)  logic [T_VAR_WID-1:0] t_var_ram [NEURON_NO-1:0]; // time fix ram	
logic [T_VAR_WID-1:0] t_thr_reg_d, t_thr_reg_dd, t_thr_reg_3d, t_thr_reg_4d, t_thr_reg_5d;
logic [T_VAR_WID-1:0] t_thr_reg_6d, t_thr_reg_7d, t_thr_reg_8d, t_thr_reg_9d, t_thr_reg_10d;
logic [T_VAR_WID-1:0] t_thr_reg_11d, t_thr_reg_12d, t_thr_reg_13d, t_thr_reg_14d;
(*ram_style = "distributed"*)  logic [T_VAR_WID-1:0] t_thr_ram [NEURON_NO-1:0];	// thrshold ram
logic sp_in_d;
logic [T_FIX_WID-1:0] ts_efa_out, ts_efa_o_m, ts_efa_o_s, ts_efa_o_th;
//logic [NEURON_LEN-1:0] dout_reg;	
logic en_d, en_2d, en_3d, nen, nen_d, nen_2d, nen_3d, nen_4d, nen_5d, nen_6d;
logic nen_7d, nen_8d, nen_9d, nen_10d, nen_11d, nen_12d, nen_13d, nen_14d;
logic [TS_WID-1:0] thr;

logic [$clog2(NEURON_NO)-1:0] addr_d, addr_dd, addr_3d, t_thr_rd_addr;
logic [$clog2(NEURON_NO)-1:0] sp_out_wr_addr, addr_6d, addr_7d, addr_8d, addr_9d;
logic [$clog2(NEURON_NO)-1:0] addr_10d, addr_11d, addr_12d, addr_13d, addr_14d, addr_15d;

logic [AMPL_WID-1:0]  ampl_a, ampl_b;
logic [AMPL_WID-1:0]  ker_a, ker_b;

logic sp_in_dd, sp_in_3d, sp_in_4d, sp_in_5d, sp_in_6d, sp_in_7d, sp_in_8d;
logic sp_in_9d, sp_in_10d, sp_in_11d, sp_in_12d, sp_in_13d, sp_in_14d, sp_in_15d;


always @(posedge clk) begin	// Converting system_en to neuron_en
	en_d 	<= en;
	en_2d 	<= en_d;
	en_3d 	<= en_2d;
end

assign nen = en_d; //en & ~en_3d;

always @(posedge clk) 
	if (reset) t_var_reg <= 0;
	else if (tsefa_cnt==1 &en==1) t_var_reg <= t_var_ram[neuron_addr]; 

always @(posedge clk) t_var_reg_d <= t_var_reg;

always @(posedge clk) // t_fix_ram writing
	if (nen==1 & tsefa_cnt==2) t_var_ram[addr_d] <= (sp_in_d) ? 1 : t_var_reg + 1;

always @(posedge clk)
	if (reset) t_thr_reg <= 0;
	else if  (nen==1 &tsefa_cnt==3) t_thr_reg <= t_thr_ram[neuron_addr]; 

assign t_reg = (nen) ? ((tsefa_cnt==1) ? t_thr_reg : t_var_reg) : 0;

always @(posedge clk) begin
	nen_d 	<= nen;
	nen_2d 	<= nen_d;
	nen_3d 	<= nen_2d;  		// ts_efa_en, srm_en and ampl_wr_en	
	nen_4d 	<= nen_3d;
	nen_5d 	<= nen_4d;
	nen_6d 	<= nen_5d;
	nen_7d 	<= nen_6d;
	nen_8d 	<= nen_7d;
	nen_9d 	<= nen_8d;
	nen_10d <= nen_9d;
	nen_11d <= nen_10d;
	nen_12d <= nen_11d;
	nen_13d <= nen_12d;
	nen_14d <= nen_13d;
end

always @(posedge clk) begin
	addr_d 			<= neuron_addr;
	addr_dd 		<= addr_d;
	addr_3d			<= addr_dd; 		// amplitute update addr for spike_in
	t_thr_rd_addr	<= addr_3d; 		// refractory reading address
	sp_out_wr_addr 	<= t_thr_rd_addr;	
	addr_6d 		<= sp_out_wr_addr;	 
	addr_7d 		<= addr_6d;	
	addr_8d 		<= addr_7d;		
	addr_9d			<= addr_8d;					
	addr_10d		<= addr_9d;	
	addr_11d		<= addr_10d;
	addr_12d		<= addr_11d;		
	addr_13d		<= addr_12d;
	addr_14d		<= addr_13d;
	addr_15d		<= addr_14d;
end

always @(posedge clk) 									// t_thr_ram writing
	if (nen_13d & tsefa_cnt==2) t_thr_ram[addr_14d] <= (sp_out) ? 1 : (t_thr_reg_13d==0 ? 0 : t_thr_reg_13d + 1);

always @(posedge clk) sp_in_d  <= input_spike;

ts_efa_var #(.SCAL_ADDR_LEN(SCAL_ADDR_LEN), .TEMP_ADDR_LEN(TEMP_ADDR_LEN), 
			 .TAU_VAR_WID(TAU_VAR_WID), .RECI_ADDR_LEN(RECI_ADDR_LEN),
			 .TAU_TH(TAU_TH), .TAU_S(TAU_S)) 
	ts_efa_var_module (
	.clk(clk),
	.reset(reset),
	.we(ext_req),
	.re(nen_8d),
	.ext_wr_addr(ext_rd_addr),
	.ext_din(ext_din),
	.re_reci(nen),
	.tsefa_cnt(tsefa_cnt),
	.t_var_thr_reg(t_reg),
	.ts_efa_out(ts_efa_out));

always @(posedge clk)
	if (reset) begin
		ts_efa_o_m <= 0;
		ts_efa_o_s <= 0;
		ts_efa_o_th <= 0;
	end
	else if (nen_8d) 
		if (tsefa_cnt==3) ts_efa_o_m <= ts_efa_out;
		else if (tsefa_cnt==1) ts_efa_o_s <= ts_efa_out; 
		else if (tsefa_cnt==2) ts_efa_o_th <= ts_efa_out;


always @(posedge clk) begin
 	t_thr_reg_d <= t_thr_reg;
 	t_thr_reg_dd <= t_thr_reg_d;
 	t_thr_reg_3d <= t_thr_reg_dd;
 	t_thr_reg_4d <= t_thr_reg_3d;
 	t_thr_reg_5d <= t_thr_reg_4d;
 	t_thr_reg_6d <= t_thr_reg_5d;
 	t_thr_reg_7d <= t_thr_reg_6d;
 	t_thr_reg_8d <= t_thr_reg_7d;
 	t_thr_reg_9d <= t_thr_reg_8d;
 	t_thr_reg_10d <= t_thr_reg_9d;
 	t_thr_reg_11d <= t_thr_reg_10d;
 	t_thr_reg_12d <= t_thr_reg_11d;
 	t_thr_reg_13d <= t_thr_reg_12d;
 	t_thr_reg_14d <= t_thr_reg_13d;
end

threshold #(.NEURON_NO(NEURON_NO), .THR(THR), .TS_WID(TS_WID), .T_FIX_WID(T_FIX_WID), .T_VAR_WID(T_VAR_WID))
	threshold_module (
	.clk(clk),
	.reset(reset),
	.t_thr_reg(t_thr_reg_11d),
	.ts_efa_o_th(ts_efa_o_th),
	.thr(thr));

spike_srm #(.TS_WID(TS_WID), .T_FIX_WID(T_FIX_WID)) 
	spike_srm_module (
	.clk(clk),
	.reset(reset),	
	.thr(thr),
	.weight_const(weight_const),
	.ampl_m(ampl_a),
	.ampl_s(ampl_b),
	.exp_m(ts_efa_o_m),
	.exp_s(ts_efa_o_s),
	.ker_m_out(ker_a),
	.ker_s_out(ker_b),
	.sp_out(sp_out));


always @(posedge clk) begin
	sp_in_dd <= sp_in_d;
	sp_in_3d <= sp_in_dd;
	sp_in_4d <= sp_in_3d;
	sp_in_5d <= sp_in_4d;  	
	sp_in_6d <= sp_in_5d;
	sp_in_7d <= sp_in_6d;
	sp_in_8d <= sp_in_7d;
	sp_in_9d <= sp_in_8d;
	sp_in_10d <= sp_in_9d;
	sp_in_11d <= sp_in_10d;
	sp_in_12d <= sp_in_11d;  	
	sp_in_13d <= sp_in_12d;
	sp_in_14d <= sp_in_13d;  	
	sp_in_15d <= sp_in_14d;
end

amplitude #(.NEURON_NO(NEURON_NO), .AMPL_WID(AMPL_WID), .TS_WID(TS_WID)) 
	amplitude_module (
	.clk(clk),
	.reset(reset),
	.sp_in(sp_in_15d),
	.sp_out(sp_out==1&tsefa_cnt==1),
	.ker_a(ker_a),
	.ker_b(ker_b),
	.re(nen_8d),
	.weight_const(weight_const),
	.rd_addr(addr_9d),
	.wr_addr(addr_15d),
	.ampl_a(ampl_a),
	.ampl_b(ampl_b));


always @(posedge clk)
	if (reset) ts_sp_addr <= 0;
	else ts_sp_addr <= (sp_out) ? {dt_ts, sp_out_wr_addr} : 0;

initial begin
	for (int i=0; i<NEURON_NO; i++) t_var_ram[i] = 0;
	for (int i=0; i<NEURON_NO; i++) t_thr_ram[i] = 0;

	en_d 		= '0;
	en_2d 		= '0;
	en_3d 		= '0;
	nen_d 		= '0;

	t_var_reg 	= '0;
	t_var_reg_d = '0;
	ts_efa_o_m 	= '0;
	ts_efa_o_s 	= '0;
	ts_efa_o_th = '0;
	nen_2d 		= '0;
	nen_3d 		= '0;	
	nen_4d 		= '0;
	nen_5d 		= '0;	
	nen_6d 		= '0;	
	nen_7d 		= '0;
	nen_8d 		= '0;	
	nen_9d 		= '0;	
	nen_10d 	= '0;	
	nen_11d 	= '0;	
	nen_12d 	= '0;	
	nen_13d 	= '0;
	nen_14d 	= '0;
	t_thr_reg   = '0;
	t_thr_reg_d  = '0;
	t_thr_reg_dd = '0;
	t_thr_reg_3d = '0;
	t_thr_reg_4d = '0;
	t_thr_reg_5d = '0; 
	t_thr_reg_6d = '0;
	t_thr_reg_7d = '0;
	t_thr_reg_8d = '0;
	t_thr_reg_9d = '0;
	t_thr_reg_10d = '0;
	t_thr_reg_11d = '0;
	t_thr_reg_12d = '0;
	t_thr_reg_13d = '0;
	t_thr_reg_14d = '0;
	addr_d  	= NEURON_NO-1;
	addr_dd 	= NEURON_NO-1;
	addr_3d 	= NEURON_NO-1;
	t_thr_rd_addr = NEURON_NO-1;
	sp_out_wr_addr = NEURON_NO-1;
	addr_6d 	= NEURON_NO-1;
	addr_7d 	= NEURON_NO-1;
	addr_8d 	= NEURON_NO-1;
	addr_9d 	= NEURON_NO-1;
	addr_10d	= NEURON_NO-1;	
	addr_11d	= NEURON_NO-1;
	addr_12d	= NEURON_NO-1;		
	addr_13d	= NEURON_NO-1;	
	addr_14d	= NEURON_NO-1;	
	addr_15d	= NEURON_NO-1;
	sp_in_d  	= '0;
	sp_in_dd 	= '0;
	sp_in_3d 	= '0;
	sp_in_4d 	= '0;
	sp_in_5d	= '0;
	sp_in_6d 	= '0;
	sp_in_7d 	= '0;
	sp_in_8d 	= '0;
	sp_in_9d 	= '0;
	sp_in_10d 	= '0;
	sp_in_11d 	= '0;
	sp_in_12d 	= '0;
	sp_in_13d 	= '0;
	sp_in_14d 	= '0;
	sp_in_15d 	= '0;
end

// always @(posedge clk)
// 	if (reset) int_rd.dout <= '0;
// 	else if (spike) begin
// 		if (int_wr_addr==3'b00) int_rd.dout <= {dt_ts, int_wr_addr};
// 		if (int_wr_addr!=3'b00) int_rd.dout <= {dt_ts, int_wr_addr+3'b01};
// 	end
	// else int_rd.dout <= '0;

// assign int_rd_addr = t_fix_wr_addr;
// assign int_rd_en = t_fix_wr_en;

	// Internal read
// always @(posedge clk)		
// 	if (reset) int_rd.dreg <= '0;						
// 	else if (int_rd_en) int_rd.dreg <= neuron_ram[int_rd_addr];		
// 	else if (dt_count > NEURON_NO-1) int_rd.dreg <= 0;

// assign int_wr_en = ts_efa_en;

// // ----------------------- External and Internal write ----------------------
// always @(posedge clk)
// 	if (int_wr_en) neuron_ram[int_wr_addr] <= int_wr.dreg;
// 	else if (ext_req == 2) neuron_ram[ext_wr_addr] <= ext_din;

// //------------------------ External process --------------------------------
// 	// External read (External signals: "ext_req = 1" enables read signal, and "ext_req = 2" enables write signal)	
// always @(posedge clk)
// 	if (reset) dout_reg <= '0;
// 	else if (ext_req == 1) dout_reg <= neuron_ram[ext_rd_addr];
// assign ext_dout = dout_reg;
endmodule
