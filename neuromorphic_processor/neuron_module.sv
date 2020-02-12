`timescale 1ns / 1ps
module neuron_module #(parameter NEURON_NO=2**8, ACTIVITY_LEN=9, REFRACTORY_LEN=4, TS_WIDTH=16, REFRACTORY_PER=4)
	(input logic 	clk, reset, 
	 input logic 	sys_en,
	 input logic 	[1:0] ext_req,
	 // input logic 	[$clog2(NEURON_NO)-1:0] ext_rd_addr, ext_wr_addr,
	 // input logic 	[NEURON_LEN-1:0] ext_din, 
	 // output logic 	[NEURON_LEN-1:0] ext_dout,
	 output logic 	[TS_WIDTH+$clog2(NEURON_NO)-1:0] ts_sp_addr,
	 output logic 	sp_out);

localparam DT = 1000;											// 1 ms/ 10 ns
localparam NEURON_LEN = ACTIVITY_LEN+REFRACTORY_LEN;																				
localparam MU_LEN = 32;
localparam AMPL_LEN = 24;
localparam MU_D = 4;
localparam EXP_LEN = 16;
localparam T_FIX_LEN = 2**20;

// struct {logic [NEURON_LEN-1:0] dreg; } int_rd;		
// struct {logic [NEURON_LEN-1:0] dreg;} int_wr;

// logic [$clog2(NEURON_NO)-1:0] int_wr_addr, int_rd_addr;
// logic int_wr_en, int_rd_en;

logic [NEURON_LEN-1:0] neuron_ram [NEURON_NO-1:0];				// Neuron memory
logic [NEURON_LEN-1:0] dout_reg;	

logic [NEURON_NO-1:0] spike_in_ram;								// spike_in 
logic sp_in, sp_in_d, sp_in_dd, sp_in_ddd;
logic sp_in_mu, sp_in_ampl;

logic ref_wr_en;
logic [REFRACTORY_LEN-1:0] ref_ram [NEURON_NO-1:0];				// refractory period ram
logic [REFRACTORY_LEN-1:0] ref_per_reg;	
logic [$clog2(NEURON_NO)-1:0] ref_rd_addr, ref_wr_addr;

logic t_fix_wr_en;
logic [$clog2(NEURON_NO)-1:0] t_fix_wr_addr;

logic ts_efa_en_ampl_wr_en;
logic [EXP_LEN-1:0] ts_efa1_out; 

logic ampl_wr_en;
logic [$clog2(NEURON_NO)-1:0] ampl_wr_addr;
logic [AMPL_LEN-1:0] ampl_val;

logic [MU_LEN-1:0] mu_in;
logic [MU_LEN+REFRACTORY_LEN-1:0] mu_out;

logic [TS_WIDTH-1:0] dt_ts;
logic sp_out;
logic [$clog2(NEURON_NO)-1:0] sp_out_wr_addr;


dt_counter #(.DT(DT), .TS_WIDTH(TS_WIDTH))
	dt_counter_module (
	.clk(clk),
	.reset(reset),
	.sys_en(sys_en),
	.dt_tick(dt_tick),
	.dt_count(dt_count),
	.dt_ts(dt_ts));

int_signal #(.NEURON_NO(NEURON_NO))
	int_singal_module (
	.clk(clk),
	.reset(reset),
	.sys_en(sys_en),
	.ext_req(ext_req),
	.dt_tick(dt_tick),
	.t_fix_wr_en(t_fix_wr_en),
	.t_fix_wr_addr(t_fix_wr_addr),
	.ts_efa_en_ampl_wr_en(ts_efa_en_ampl_wr_en),
	.ref_wr_en(ref_wr_en),
	.ref_wr_addr(ref_wr_addr),
	.ampl_wr_addr(ampl_wr_addr),
	.sp_out_wr_addr(sp_out_wr_addr),
	.srm_en);

assign sp_in = (t_fix_wr_en) ? spike_in_ram[t_fix_wr_addr] : 0; // Spike input 

always @(posedge clk) begin
	sp_in_d <= sp_in;
	sp_in_dd <= sp_in_d;
	sp_in_ddd <= sp_in_dd;
	sp_in_ampl <= sp_in_ddd;  // amplitue reset spike_in
end
assign sp_in_mu = sp_in_ampl;

ts_efa #(.TS_WIDTH(TS_WIDTH), .EXP_LEN(EXP_LEN), 
		 .T_FIX_LEN(T_FIX_LEN), .NEURON_NO(NEURON_NO)) 
	ts_efa1_module (
	.clk(clk),
	.reset(reset),
	.ts_efa_en(ts_efa_en_ampl_wr_en),
	.t_fix_wr_en(t_fix_wr_en),
	.t_fix_wr_addr(t_fix_wr_addr),
	.sp_in(sp_in),
	.sp_out(sp_out),
	.ts_efa_out(ts_efa1_out));	

amplitude #(.NEURON_NO(NEURON_NO),.AMPL_LEN(AMPL_LEN),.MU_LEN(MU_LEN)) 
	amplitude_module (
	.clk(clk),
	.reset(reset),
	.wr_en(ts_efa_en_ampl_wr_en),
	.sp_in(sp_in_ampl),
	.sp_out(sp_out),
	.mu_in(mu_in),
	.wr_addr(ampl_wr_addr),
	.ampl_out(ampl_val));

assign ref_rd_addr = ampl_wr_addr;					

always @(posedge clk)											// refractory writing 
	if (ref_wr_en) ref_ram[ref_wr_addr] <= mu_out[REFRACTORY_LEN-1:0];
assign ref_per_reg = ref_ram[ref_rd_addr];  					// refgractory period value

spike_srm #(
	.MU_LEN(MU_LEN), 
	.EXP_LEN(EXP_LEN),
	.AMPL_LEN(AMPL_LEN),
	.REFRACTORY_LEN(REFRACTORY_LEN), 
	.REFRACTORY_PER(REFRACTORY_PER)) 
	spike_srm_module (
	.clk(clk),
	.reset(reset),	
	.srm_en(srm_en),
	.sp_in(sp_in_mu),
	.ampl_val(ampl_val),
	.exp_func_val(ts_efa1_out),
	.ref_per_val(ref_per_reg),
	.mu_in(mu_in),
	.sp_out(sp_out),
	.mu_out(mu_out));

always @(posedge clk)
	if (reset) ts_sp_addr <= 0;
	else ts_sp_addr <= (sp_out) ? {dt_ts, sp_out_wr_addr} : 0;

initial begin
	// for (int i=0; i<NEURON_NO; i++) begin
	// 	if (i==0) neuron_ram[i] = 13'hc63;					// 1ff = 512 Hz
	// 	else if (i==NEURON_NO/2) neuron_ram[i] = 13'hc73;	// c8 = 200 Hz
	// 	else if (i==NEURON_NO-1) neuron_ram[i] = 13'hc83;	// 6 = ?? Hz
	// 	else neuron_ram[i] = 0;
	// end
	for (int i=0; i<NEURON_NO; i++) begin
		ref_ram[i] = 4;   									// 1ms								
	end
	for (int i=0; i<NEURON_NO; i++) begin
		if (i==255) spike_in_ram[i] = 1;
		else if (i==0) spike_in_ram[i] = 1;
		else spike_in_ram[i] = 0;
	end

	dout_reg = '0;		

	sp_in_d = '0;
	sp_in_dd = '0;
	sp_in_ddd = '0;
	sp_in_ampl = '0;
	ts_sp_addr = '0;
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
