`timescale 1ns / 1ps
module main
	(input logic  	sysclk,
	 input logic 	rx_din,
	 input logic 	[1:0] btn, 	//sw6.3 center	
	 output logic 	pio44,		//csb
	 output logic 	pio4,  		//sck
	 output logic 	pio5,  		//holdb
	 output logic 	pio36,  	//wpb
	 output logic 	pio3,  		//sdi
	 input logic 	pio45,		//sdo
	 output logic 	tx_dout); 	

localparam CLK_SCK_SCAL = 10;  //sck_period/clk_peirod  = 1000n/100n 
localparam OP_CYC = 8;
localparam HOLD_CYC = 10;
localparam WP_CYC = 10;
localparam SER_LEN = 8;
localparam NO_ADDR = 4;
localparam SER_ADDR = 32;
localparam FIFO_NO = 6;

logic clk, reset, comm_pause, wr_pause;

holdb_gen #(.CLK_SCK_SCAL(CLK_SCK_SCAL),.HOLD_CYC(HOLD_CYC)) hold_bar_module(
	.clk(clk),.reset(reset),.comm_pause(comm_pause),.holdb(holdb));

wpb_gen #(.CLK_SCK_SCAL(CLK_SCK_SCAL),.WP_CYC(WP_CYC)) write_protect_bar_module(
	.clk(clk),.reset(reset),.wr_pause(wr_pause),.wpb(wpb));

clk_wiz_1 clk1_module (.clk_in1(sysclk),.clk_out1(clk));				

btn_pulser btn_pulser(.clk(clk),.btn_in(btn[0]),.btn_out(reset));
btn_pulser btn_comm_pause_module (.clk(clk), .btn_in(btn[1]), .btn_out(comm_pause));
btn_pulser btn_write_pause_module (.clk(clk), .btn_in(btn[1]), .btn_out(wr_pause));

logic rx_done;					// rx ready signal
logic [SER_LEN-1:0] rx_dout;				// output data from uart rx

uart_rx #(.CLKS_PER_BIT(869)) uart_rx( 
	.i_Clock(clk),.i_Rx_Serial(rx_din),
	.o_Rx_DV(rx_done),.o_Rx_Byte(rx_dout));

logic [SER_LEN-1:0] inst, status, addr1, addr2, din1, dummy;
logic sysen;
logic [1:0] ser_rd;

op_mode #(.SER_LEN(SER_LEN)) op_mode_generation(
	.clk(clk),.reset(reset),.rx_done(rx_done),.rx_dout(rx_dout),
	.inst(inst),.status(status),.addr1(addr1),.addr2(addr2),.din1(din1),.dummy(dummy),
	.sysen(sysen),.ser_rd(ser_rd));

logic csb_pre_norm, csb_norm, csb_pre_multi, csb_multi;
logic csb_pre, sck, csb, holdb, wpb;

csb_gen #(.CLK_SCK_SCAL(CLK_SCK_SCAL*10),.OP_CYC(OP_CYC),.SER_LEN(SER_LEN),.SER_ADDR(SER_ADDR)) csb_normal_module(
	.clk(clk),.reset(reset),
	.inst(inst),.sysen(sysen),.ser_rd(ser_rd),
	.csb_pre(csb_pre_norm),.csb(csb_norm)); 	// 1 MHz 

csb_gen #(.CLK_SCK_SCAL(CLK_SCK_SCAL),.OP_CYC(OP_CYC*(4+NO_ADDR)),.SER_ADDR(SER_ADDR)) chip_select_bar_multi_module(
	.clk(clk),.reset(reset),
	.inst(inst),.sysen(sysen),
	.csb_pre(csb_pre_multi),.csb(csb_multi));	// 10 MHz

sck_gen #(.CLK_SCK_SCAL(CLK_SCK_SCAL*10),.SER_LEN(SER_LEN)) sck_generation_module(
	.clk(clk),.reset(reset),
	.inst(inst),.csb(csb_pre),.sck(sck));

assign csb_pre = csb_pre_norm;
assign csb = csb_norm;

logic sdi_norm, sdi_multi, sdi;
logic [$clog2(OP_CYC*(3+SER_ADDR))-1:0] sck_cnt_norm;
logic [$clog2(OP_CYC*(3+SER_ADDR))-1:0] sck_cnt_multi;
logic [$clog2(OP_CYC*(3+SER_ADDR))-1:0] sck_cnt;

sdi_gen_2byte #(.CLK_SCK_SCAL(CLK_SCK_SCAL*10),.OP_CYC(OP_CYC),.SER_ADDR(SER_ADDR)) sdi_1_to_4byte_serializer_module(
	.clk(clk),.reset(reset),.csb(csb_pre),.inst(inst),.status(status),
	.addr1(addr1),.addr2(addr2),.din1(din1),.dummy(dummy),
	.sck_cnt(sck_cnt_norm),.data_out(sdi_norm));

sdi_gen_multi #(.CLK_SCK_SCAL(CLK_SCK_SCAL),.OP_CYC(OP_CYC),.NO_ADDR(NO_ADDR)) sdi_multi_serializer_module(
	.clk(clk),.reset(reset),.csb(csb_pre),.inst(inst),.addr1(addr1),.addr2(addr2),.dummy(dummy),
	.sck_cnt(sck_cnt_multi),.data_out(sdi_multi));

assign sdi = sdi_norm;
assign sck_cnt = sck_cnt_norm; //(inst==11) ? sck_cnt_multi : sck_cnt_norm;

(*ram_style = "distributed"*) logic [SER_LEN*NO_ADDR-1:0] input_lut[15:0];	
logic [SER_LEN*NO_ADDR-1:0] x;
logic [$clog2(SER_LEN*NO_ADDR)-1:0] pcnt;
logic tx_rdy_multi;
logic [SER_LEN-1:0] sdo_par;
logic sdo_par_rdy;
logic sdo_ser_rdy, sdo_ser;
logic fifo_tx_rdy, fifo_rd_en;
logic [SER_LEN-1:0] fifo_din, fifo_dout;
logic fifo_din_rdy;

sdo_read #(.OP_CYC(OP_CYC),.SER_LEN(SER_LEN),.SER_ADDR(SER_ADDR)) sdo_read_module(
	.clk(clk),.reset(reset),
	.inst(inst),.ser_rd(ser_rd),
	.sck(sck),.sck_cnt(sck_cnt),
	.sdo_port(pio45),.sdo_par_rdy(sdo_par_rdy),.sdo_par(sdo_par),
	.din_rdy(sdo_ser_rdy),.sdo_ser(sdo_ser));

logic cnt_val_rdy;
logic [$clog2(SER_ADDR*SER_LEN):0] cnt_val;

bit_count #(.OP_CYC(OP_CYC),.SER_LEN(SER_LEN),.SER_ADDR(SER_ADDR)) bit_count_module(
	.clk(clk),.reset(reset),
	.sdo_ser_rdy(sdo_ser_rdy),.sdo_ser(sdo_ser),.sck_cnt(sck_cnt),
	.cnt_val(cnt_val),.cnt_val_rdy(cnt_val_rdy));

assign fifo_din_rdy = (inst==3&ser_rd==2) ? cnt_val_rdy : sdo_par_rdy;
assign fifo_din = (inst==3&ser_rd==2) ? cnt_val : sdo_par;

fifo #(.FIFO_NO(FIFO_NO),.SER_LEN(SER_LEN)) fifo_module(
	.clk(clk),.reset(reset),
	.din_rdy(fifo_din_rdy),.din(fifo_din),.tx_active(tx_active),.tx_done(tx_done),
	.full(full),.empty(empty),
	.rd_rdy(fifo_rd_en),.dout(fifo_dout));

uart_tx #(.CLKS_PER_BIT(869)) uart_tx_norm_module(
 	.i_Clock(clk),.i_Tx_DV(fifo_rd_en),.i_Tx_Byte(fifo_dout),
 	.o_Tx_Active(tx_active),.o_Tx_Serial(tx_dout),.o_Tx_Done(tx_done));	

initial $readmemb("C:/Users/KJS/PROJECT_WS/fpga_projects/rm25c256ds_control/input.mem", input_lut);
//initial $readmemb("C:/Users/427/Desktop/rm25c256ds_control/input.mem", input_lut);

assign x = input_lut[0];

always @(posedge clk)
	if (reset) pcnt <= 0;
	else if (sck_cnt>31&sdo_ser_rdy) pcnt <= (x[sck_cnt-SER_LEN*NO_ADDR]==1) ? ((sdo_ser==1) ? pcnt : pcnt+1) : ((sdo_ser==1) ? pcnt+1 : pcnt); 

always @(posedge clk)
	if (reset) tx_rdy_multi <= 0;
	else if (sck_cnt==63) tx_rdy_multi <= sdo_ser_rdy? 1 : 0;

assign pio36 = wpb;
assign pio5 = holdb;
assign pio4 = sck;
assign pio44 = csb;
assign pio3 = sdi;

initial begin
	pcnt = 0;
	tx_rdy_multi = 0;
end
endmodule
