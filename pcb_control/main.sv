`timescale 1ns / 1ps
module main
	 (input logic sysclk,
      input logic [1:0] btn,   
	  output logic [1:0] led,
	  input logic rx_data_in,					// Uart data from PC from 1 to 30
	  output logic tx_data_out,					// Uart data to PC 	
	  output logic pio2, pio3, pio4, pio5,		// Column shift register data in
	  output logic pio6, pio7, pio8, pio9,
	  output logic pio20, pio21, pio22, pio23);	// Row shift register data in 

parameter LED_CNT_MAX = 10**6; 					// 1ms
//parameter PULSE_W = 1000;	   					// 10us(target_pulseperiod)/10ns(clk_period)
parameter PULSE_W = 10**6;	   
parameter PULSE_DC = 50;       
parameter PULSE_NO = 5;
parameter NO_ROW = 30;
parameter NO_COL = 30;
parameter SW_WID = 4;

logic clk1, clk2;

clk_wiz_0 clk0_module (
	.clk_in1(sysclk), 					// Period: 83 ns
	.clk_out1(clk1), 					// 6M Hz => period 166 ns
	.clk_out2(clk2)); 					// 12M Hz => period 83 ns

btn_pulser btn_reset_module (.clk(clk1), .btn_in(btn[0]), .btn_out(reset));
btn_pulser btn_sysen_module (.clk(clk1), .btn_in(btn[1]), .btn_out(sys_en));
//led_control #(.LED_CNT_MAX(LED_CNT_MAX)) led0_module (	.clk(clk1), .reset(reset), 	.sys_en(sys_en), .led(led[0]));

// Uart rx module   6,000,000/115,200 = 52.0833
uart_rx #(.CLKS_PER_BIT(52)) uart_rx( 	
	.i_Clock(clk1),
	.i_Rx_Serial(rx_data_in),					
	.o_Rx_DV(rx_done),					// RX done signal		
	.o_Rx_Byte(rx_data_out));			
						
logic [7:0] rx_data_out;				// Data from PC to 8 bit  
logic [7:0] tx_data_in;					// Data from RX to TX
logic tx_ready;							// TX ready signal (one delay from rx_done can be used)
logic tx_active;						// Active while 8 bit TX signal to be Serial 
logic tx_done;							// TX done signal

always @(posedge clk1) tx_ready <= rx_done;	
always @(posedge clk1) tx_data_in <= (rx_done) ? rx_data_out : 0;

// Uart tx module  (6,000,000/115,200=52.0833), (5,000,000/115,200=44), (10,000,000/115,200=87)
uart_tx #(.CLKS_PER_BIT(52)) uart_tx(   
	.i_Clock(clk1),
	.i_Tx_DV(tx_ready),
	.i_Tx_Byte(tx_data_in),				 
	.o_Tx_Active(tx_active),
	.o_Tx_Serial(tx_data_out),			
	.o_Tx_Done(tx_done));

sm state_machine_module(
	.clk1(clk1), .clk2(clk2), .reset(reset), 
	.rx_done(rx_done), .rx_data_out(rx_data_out),
    .sft_clk(sft_clk), .sft_rst(sft_rst),
    .latch_clk_d(latch_clk), .oe(oe),
	.sr_sdi_c1c8(sr_sdi_c1c8), .sr_sdi_c9c15(sr_sdi_c9c15), .sr_sdi_c16c23(sr_sdi_c16c23), .sr_sdi_c24c30(sr_sdi_c24c30),
	.sr_sdi_r1r8(sr_sdi_r1r8), .sr_sdi_r9r15(sr_sdi_r9r15), .sr_sdi_r16r23(sr_sdi_r16r23), .sr_sdi_r24r30(sr_sdi_r24r30));

assign pio2 = sr_sdi_c24c30;
assign pio3 = sr_sdi_c16c23;
assign pio4 = sr_sdi_c9c15;
assign pio5 = sr_sdi_c1c8;

assign pio6 = sft_rst;			// shift register reset: active low
assign pio7 = sft_clk;			
assign pio8 = latch_clk;
assign pio9 = oe;				// Output enable signal: active low

assign pio20 = sr_sdi_r1r8;
assign pio21 = sr_sdi_r9r15;
assign pio22 = sr_sdi_r16r23;
assign pio23 = sr_sdi_r24r30;

logic led0, led1;

always @(posedge clk1)
	if (reset) begin
		led0 <= 0;
		led1 <= 1;
	end
	else begin
		led0 <= ~led0;
		led1 <= ~led1;
	end

assign led[0] = led0;
assign led[1] = led1;

initial begin
	tx_ready 	= 0;
	tx_data_in 	= 0;

	led0 		= 0;
	led1 		= 1;
end
endmodule