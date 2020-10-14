`timescale 1ns / 1ps
module neuron_module #(parameter NEURON_NO=1, TS_WID=12)
	(input logic 	sys_en, clk1, clk2, 
	 input logic 	reset, 
	 input logic 	[1:0] ext_req,
	 input logic 	[5:0] ram_sel,
	 input logic 	[T_FIX_WID/2-1:0] ext_rd_addr, 
	 input logic 	[T_FIX_WID/2-1:0] ext_wr_addr,
	 input logic 	[T_FIX_WID-1:0] ext_din, 
	 output logic 	[T_FIX_WID-1:0] ext_dout,
	 input logic 	en,
	 input logic 	input_spike,
	 input logic 	[TS_WID-1:0] weight_const,
	 input logic	[TS_WID-1:0] dt_ts,
	 input logic	[$clog2(NEURON_NO)-1:0] n_addr,
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

//logic [NEURON_LEN-1:0] dout_reg;	
logic en_d, en_dd, en_3d, en_4d, en_5d, en_6d, en_7d, en_8d;
logic [$clog2(NEURON_NO)-1:0] addr_d, addr_dd, addr_3d, t_thr_rd_addr;
logic [$clog2(NEURON_NO)-1:0] sp_out_wr_addr, addr_6d, addr_7d, addr_8d, addr_9d;
logic sp_in_d, sp_in_dd, sp_in_3d, sp_in_4d, sp_in_5d, sp_in_6d, sp_in_7d, sp_in_8d, sp_in_9d;
logic [T_FIX_WID-1:0] t_fix_ms_reg, t_fix_ms_reg_d;
(*ram_style = "distributed"*)  logic [T_FIX_WID-1:0] t_fix_ram [NEURON_NO-1:0]; 	// time fix ram	
(*ram_style = "distributed"*)  logic [T_FIX_WID-1:0] t_thr_ram [NEURON_NO-1:0];	// thrshold ram
logic [T_FIX_WID-1:0] ts_efa_a_out, ts_efa_b_out;  
logic [T_FIX_WID-1:0] t_thr_reg, t_thr_reg_d, t_thr_reg_dd, t_thr_reg_3d, t_thr_reg_4d; 
logic [T_FIX_WID-1:0] t_thr_reg_5d, t_thr_reg_6d, t_thr_reg_7d, t_thr_reg_8d;
logic [AMPL_WID-1:0] ampl_a, ampl_b;
logic [AMPL_WID-1:0] ker_a, ker_b;
logic [T_FIX_WID-1:0] thr;

logic sel;
logic [T_FIX_WID-1:0] t_fix_reg, ts_efa_m, ts_efa_s, ts_efa_thr;

always @(posedge clk1) begin
	en_d 	<= en;
	en_dd 	<= en_d;
	en_3d 	<= en_dd;  		// ts_efa_en, srm_en and ampl_wr_en	
	en_4d 	<= en_3d;
	en_5d 	<= en_4d;
	en_6d 	<= en_5d;
	en_7d 	<= en_6d;
	en_8d 	<= en_7d;
end

always @(posedge clk1) begin
	addr_d 			<= n_addr;
	addr_dd 		<= addr_d;
	addr_3d			<= addr_dd; 		// amplitute update addr for spike_in
	t_thr_rd_addr	<= addr_3d; 		// refractory reading address
	sp_out_wr_addr 	<= t_thr_rd_addr;	
	addr_6d 		<= sp_out_wr_addr;	 
	addr_7d 		<= addr_6d;	
	addr_8d 		<= addr_7d;			
	addr_9d 		<= addr_8d;				
end

assign t_fix_ms_reg = (en) ? t_fix_ram[n_addr] : 0; 

assign t_thr_reg = (en) ? t_thr_ram[n_addr] : 0;

assign sel = ~clk1;
assign t_fix_reg = (~sel) ? t_fix_ms_reg : t_thr_reg;

always @(posedge clk1)
	t_fix_ms_reg_d <= t_fix_ms_reg;

always @(posedge clk1)	// t_fix_ram writing
	if (en_d) t_fix_ram[addr_d] <= (sp_in_d) ? 1 : t_fix_ms_reg_d+1;

ts_efa_A #(.SCAL_ADDR_LEN(SCAL_ADDR_LEN), .TEMP_ADDR_LEN(TEMP_ADDR_LEN)) 
	ts_efa_A_module (
	.clk(clk2),
	.reset(reset),
	.we(ext_req),
	.ram_sel(ram_sel),
	.ext_wr_addr(ext_rd_addr),
	.ext_din(ext_din),
	.re(en),
	.t_fix_reg(t_fix_reg),
	.ts_efa_a_out(ts_efa_a_out));

always @(posedge clk2) 
	if (reset) begin 
		ts_efa_m <= 0;
		ts_efa_thr <= 0;
	end
	else if (sel) begin
		ts_efa_m <= ts_efa_a_out;
	end
	else if (~sel) ts_efa_thr <= ts_efa_a_out;

always @(posedge clk1)
	if (reset) ts_efa_s <= 0;
	else ts_efa_s <= ts_efa_b_out;

ts_efa_B #(.SCAL_ADDR_LEN(SCAL_ADDR_LEN), .TEMP_ADDR_LEN(TEMP_ADDR_LEN)) 
	ts_efa_B_module (
	.clk(clk2),
	.reset(reset),
	.we(ext_req),
	.ram_sel(ram_sel),
	.ext_wr_addr(ext_rd_addr),
	.ext_din(ext_din),
	.re(en),
	.t_fix_reg(t_fix_ms_reg),
	.ts_efa_b_out(ts_efa_b_out));


always @(posedge clk1) begin
	sp_in_d  <= input_spike;
	sp_in_dd <= sp_in_d;
	sp_in_3d <= sp_in_dd;
	sp_in_4d <= sp_in_3d;
	sp_in_5d <= sp_in_4d;  	
	sp_in_6d <= sp_in_5d;
	sp_in_7d <= sp_in_6d;
	sp_in_8d <= sp_in_7d;
	sp_in_9d <= sp_in_8d;
end

// assign t_thr_reg = (en) ? t_thr_ram[n_addr] : 0; 				// time_fix value

always @(posedge clk1) begin
 	t_thr_reg_d <= t_thr_reg;
 	t_thr_reg_dd <= t_thr_reg_d;
 	t_thr_reg_3d <= t_thr_reg_dd;
 	t_thr_reg_4d <= t_thr_reg_3d;
 	t_thr_reg_5d <= t_thr_reg_4d;
 	t_thr_reg_6d <= t_thr_reg_5d;
 	t_thr_reg_7d <= t_thr_reg_6d;
 	t_thr_reg_8d <= t_thr_reg_7d;
end

always @(posedge clk1) 									// t_thr_ram writing
	if (en_8d) t_thr_ram[addr_8d] <= (sp_out) ? 1 : (t_thr_reg_8d==0 ? 0 : t_thr_reg_8d+1);

amplitude #(.NEURON_NO(NEURON_NO), .AMPL_WID(AMPL_WID)) 
	amplitude_module (
	.clk(clk1),
	.reset(reset),
	.sp_in(sp_in_8d),
	.sp_out(sp_out),
	.ker_a(ker_a),
	.ker_b(ker_b),
	.re(en_3d),
	.weight_const(weight_const),
	.rd_addr(addr_3d),
	.wr_addr(addr_8d),
	.ampl_a(ampl_a),
	.ampl_b(ampl_b));

spike_srm #(.TS_WID(TS_WID), .T_FIX_WID(T_FIX_WID)) 
	spike_srm_module (
	.clk(clk1),
	.reset(reset),	
	.weight_const(weight_const),
	.ampl_m(ampl_a),
	.ampl_s(ampl_b),
	.exp_m(ts_efa_m),
	.exp_s(ts_efa_b_out),
	.thr(thr),
	.ker_m_out(ker_a),
	.ker_s_out(ker_b),
	.sp_out(sp_out));

threshold #(.NEURON_NO(NEURON_NO), .THR(THR), .TS_WID(TS_WID), .T_FIX_WID(T_FIX_WID))
	threshold_module (
	.clk(clk1),
	.reset(reset),
	.t_thr_reg(t_thr_reg_5d),
	.thr_ts_efa_out(ts_efa_thr),
	.thr(thr));

always @(posedge clk1)
	if (reset) ts_sp_addr <= 0;
	else ts_sp_addr <= (sp_out) ? {dt_ts, sp_out_wr_addr} : 0;

initial begin
	for (int i=0; i<NEURON_NO; i++) t_fix_ram[i] = 0;
	for (int i=0; i<NEURON_NO; i++) t_thr_ram[i] = 0;

	//dout_reg = '0;
	en_d  = '0;
	en_dd = '0;
	en_3d = '0;	
	en_4d = '0;
	en_5d = '0;	
	en_6d = '0;	
	en_7d = '0;
	en_8d = '0;	

	addr_d  = NEURON_NO-1;
	addr_dd = NEURON_NO-1;
	addr_3d = NEURON_NO-1;
	t_thr_rd_addr = NEURON_NO-1;
	sp_out_wr_addr = NEURON_NO-1;
	addr_6d = NEURON_NO-1;
	addr_7d = NEURON_NO-1;
	addr_8d = NEURON_NO-1;
	addr_9d = NEURON_NO-1;

	sp_in_d  = '0;
	sp_in_dd = '0;
	sp_in_3d = '0;
	sp_in_4d = '0;
	sp_in_5d = '0;
	sp_in_6d = '0;
	sp_in_7d = '0;
	sp_in_8d = '0;
	sp_in_9d = '0;

	t_fix_ms_reg_d  = '0;
	ts_efa_m 		= '0;
	ts_efa_s 		= '0;
	ts_efa_thr 		= '0;


	t_thr_reg_d  = '0;
	t_thr_reg_dd = '0;
	t_thr_reg_3d = '0;
	t_thr_reg_4d = '0;
	t_thr_reg_5d = '0; 
	t_thr_reg_6d = '0;
	t_thr_reg_7d = '0;
	t_thr_reg_8d = '0;
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
