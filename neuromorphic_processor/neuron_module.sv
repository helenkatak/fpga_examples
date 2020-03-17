`timescale 1ns / 1ps
module neuron_module #(parameter NEURON_NO=2**8, TS_WID=20)
	(input logic 	sys_en, clk1, clk2, 
	 input logic 	reset, 
	 input logic 	[1:0] ext_req,
	 // input logic 	[$clog2(NEURON_NO)-1:0] ext_rd_addr, ext_wr_addr,
	 // input logic 	[NEURON_LEN-1:0] ext_din, 
	 // output logic 	[NEURON_LEN-1:0] ext_dout,
	 input logic 	en,
	 input logic 	sp_in,
	 input logic 	[TS_WID-1:0] weight,
	 input logic	[TS_WID-1:0] dt_ts,
	 input logic	[$clog2(NEURON_NO)-1:0] addr_in,
	 input logic 	sel,
	 output logic 	[TS_WID+$clog2(NEURON_NO)-1:0] ts_sp_addr,
	 output logic 	sp_out);

localparam UREF = 8;			// FXnum(0.002, FXfamily(12,2))
localparam TAU_M = 163;  		// FXnum(0.04, FXfamily(12,2))
localparam CREF = 204; 			// uref/tau_m = 2097/41943 = 0.002/0.04 = 0.05 = FXnum(0.05, FXfamily(12,2))
localparam THR0 = 20;			// FXnum(0.005, FXfamily(12,2))
localparam THR = 409;			// THR0/C_REF = FXnum(0.1, FXfamily(16,2))
localparam NEURON_LEN = 13;																				
localparam MU_WID = TS_WID;
localparam AMPL_WID = TS_WID;
localparam SCAL_ADDR_LEN = 8;
localparam TEMP_ADDR_LEN = 8;
localparam T_FIX_WID = SCAL_ADDR_LEN + TEMP_ADDR_LEN;

//logic [NEURON_LEN-1:0] dout_reg;	
logic testing_en, testing_en_d, testing_en_dd, update_en, testing_en_dddd, testing_en_ddddd;
logic [$clog2(NEURON_NO)-1:0] testing_addr, testing_addr_d, testing_addr_dd, testing_addr_ddd, testing_addr_dddd, sp_out_wr_addr;
logic sp_in_d, sp_in_dd, sp_in_ampl, sp_in_ampl_d, sp_in_ampl_dd, sp_in_mu;
logic [T_FIX_WID-1:0] t_fix_reg, t_thr_reg; 
(*ram_style = "block"*)  logic [T_FIX_WID-1:0] t_fix_ram [NEURON_NO-1:0]; 				// time fix ram	
(*ram_style = "block"*)  logic [T_FIX_WID-1:0] t_thr_ram [NEURON_NO-1:0];					// thrshold ram
logic [NEURON_NO-1:0] t_thr_flag;
logic [T_FIX_WID-1:0] ts_efa_a_out, thr_ts_efa_out, ts_efa_b_out; 

logic [AMPL_WID-1:0] ampl_a_val, ampl_b_val;
logic [MU_WID-1:0] ker_a, ker_b;
logic [MU_WID-1:0] mu_out;
logic [MU_WID-1:0] thr;
logic sp_out;

assign testing_en = en;

always @(posedge clk1) begin
	testing_en_d 	<= testing_en;
	testing_en_dd 	<= testing_en_d;
	update_en 		<= testing_en_dd;
	testing_en_dddd <= update_en;
	testing_en_ddddd <= testing_en_dddd;
end

assign testing_addr = addr_in;

always @(posedge clk1) begin
	testing_addr_d 		<= testing_addr;
	testing_addr_dd 	<= testing_addr_d;
	testing_addr_ddd 	<= testing_addr_dd;
	testing_addr_dddd 	<= testing_addr_ddd;
	sp_out_wr_addr 		<= testing_addr_dddd;
end

always @(posedge clk1)
	if (testing_en|testing_en_d) t_fix_ram[testing_addr] <= (sp_in) ? 1 : ((sel) ? t_fix_ram[testing_addr]+1 : t_fix_ram[testing_addr]);
assign t_fix_reg = (testing_en|testing_en_d) ? (sel ? t_fix_ram[testing_addr] : t_thr_ram[testing_addr_d]) : 0; 					// time_fix value

ts_efa_A #(.SCAL_ADDR_LEN(SCAL_ADDR_LEN), .TEMP_ADDR_LEN(TEMP_ADDR_LEN)) 
	ts_efa_A_module (
	.clk(clk1),
	.reset(reset),
	.ts_efa_out_en(update_en),
	.t_fix_reg(t_fix_reg),
	.ts_efa_a_out(ts_efa_a_out));											

always @(posedge clk1) begin
	sp_in_d <= sp_in;
	sp_in_dd <= sp_in_d;
	sp_in_ampl <= sp_in_dd;
	sp_in_ampl_d <= sp_in_ampl;
	sp_in_ampl_dd <= sp_in_ampl_d;  												// amplitue reset spike_in
end
assign sp_in_mu = sp_in_ampl_dd;

always @(posedge clk1)
	if (reset) t_thr_flag[testing_addr_ddd] <= 0;
	else if (sp_out) t_thr_flag[testing_addr_dddd] <= 1;

always @(posedge clk1) 														// t_thr_ram writing
	if (update_en|testing_en_ddddd) t_thr_ram[sp_out_wr_addr] <= (sp_out) ? 1 : (t_thr_flag[sp_out_wr_addr]==0 ? 0 : (testing_en_dddd ? t_thr_ram[sp_out_wr_addr]+1:t_thr_ram[sp_out_wr_addr]));

assign thr_ts_efa_out = (sel) ? ts_efa_a_out : 0;

ts_efa_B #(.SCAL_ADDR_LEN(SCAL_ADDR_LEN), .TEMP_ADDR_LEN(TEMP_ADDR_LEN)) 
	ts_efa_B_module (
	.clk(clk1),
	.reset(reset),
	.ts_efa_out_en(update_en),
	.t_fix_reg(t_fix_reg),
	.ts_efa_b_out(ts_efa_b_out));

amplitude #(.NEURON_NO(NEURON_NO), .AMPL_WID(AMPL_WID), .MU_LEN(MU_WID)) 
	amplitude_module (
	.clk(clk1),
	.reset(reset),
	.rd_en(update_en),
	.rd_addr(testing_addr_ddd),
	.sp_in(sp_in_mu),
	.sp_out(sp_out),
	.ker_a(ker_a),
	.ker_b(ker_b),
	.ampl_a_out(ampl_a_val),
	.ampl_b_out(ampl_b_val));

threshold #(.NEURON_NO(NEURON_NO), .THR(THR), .TS_WID(TS_WID), .T_FIX_WID(T_FIX_WID))
	threshold_module (
	.clk(clk1),
	.reset(reset),
	.t_thr_flag(t_thr_flag),
	.t_thr_rd_addr(testing_addr_dddd),
	.thr_ts_efa_out(thr_ts_efa_out),
	.thr(thr));

spike_srm #(.TS_WID(TS_WID), .T_FIX_WID(T_FIX_WID)) 
	spike_srm_module (
	.clk(clk1),
	.reset(reset),	
	.update_en(testing_en_dddd),
	.weight(weight),
	.sel(sel),
	.ampl_a_val(ampl_a_val),
	.ampl_b_val(ampl_b_val),
	.exp_func_val_a(ts_efa_a_out),
	.exp_func_val_b(ts_efa_b_out),
	.thr(thr),
	.ker_a(ker_a),
	.ker_b(ker_b),
	.sp_out(sp_out),
	.sp_in(sp_in_mu),
	.mu_out(mu_out));

always @(posedge clk1)
	if (reset) ts_sp_addr <= 0;
	else ts_sp_addr <= (sp_out) ? {dt_ts, sp_out_wr_addr} : 0;

initial begin
	for (int i=0; i<NEURON_NO; i++) t_fix_ram[i] = 0;
	for (int i=0; i<NEURON_NO; i++) t_thr_ram[i] = 0;

	//dout_reg = '0;	
	testing_en_d = 0;
	testing_en_dd = 0;
	update_en =0;
	testing_en_dddd = 0;
	testing_en_ddddd = 0;

	testing_addr_d = NEURON_NO-1;
	testing_addr_dd = NEURON_NO-1;
	testing_addr_ddd = NEURON_NO-1;
	testing_addr_dddd = NEURON_NO-1;
	sp_out_wr_addr = NEURON_NO-1;

	sp_in_d = '0;
	sp_in_dd = '0;
	sp_in_ampl = '0;
	sp_in_ampl_d ='0;
	sp_in_ampl_dd ='0;

	ts_sp_addr = '0;
	t_thr_flag = '0;
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

	// Spike generation using Poisson spike generation module
// spike_poisson #(								
// 	.ACTIVITY_LEN(ACTIVITY_LEN), 
// 	.REFRACTORY_LEN(REFRACTORY_LEN), 
// 	.REFRACTORY_PER(REFRACTORY_PER)) 
// 	spike_module (
// 	.clk(clk),
// 	.reset(reset),
// 	.poisson_en(~ext_req),
// 	.poisson_in(int_rd.dreg),
// 	.poisson_out(int_wr.dreg),
// 	.spike_out(spike));


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
