`timescale 1ns / 1ps
module system_ctrl #(parameter TD_WIDTH=16, NEURON_NO=256, UART_DATA_LEN=8, UART_CYC=3, NEURON_LEN= 13)
	(input logic 	clk, 
	 input logic	reset,
	 input logic 	rx_din,	 
	 output logic 	[UART_DATA_LEN-1:0] led,
	 output logic 	sys_en,
	 output logic 	fifo_rd,
	 output logic 	[1:0] ext_req,
	 output logic	[$clog2(NEURON_NO)-1:0] ext_rd_addr, ext_wr_addr,
	 input logic    [NEURON_LEN-1:0] ext_neur_data_out, 
	 output logic   [NEURON_LEN-1:0] ext_neur_data_in,
	 input logic 	spike,
	 input logic 	[TD_WIDTH+$clog2(NEURON_NO)-1:0] fifo_dout,
	 output logic 	tx_dout);

struct {
	logic [UART_DATA_LEN-1:0] dout;
	logic rdy;
} rx;

struct {
	logic dv;
	logic [UART_DATA_LEN-1:0] din;
	logic active;
	logic done, done_d1, done_d2;
	logic din_rdy_d1, din_rdy_d2, din_rdy;
	logic [TD_WIDTH+$clog2(NEURON_NO)-1:0] din_reg;
} tx;

struct {
	logic en;
	logic [$clog2(NEURON_NO)-1:0] addr;						// External read or write enable
	logic rd_en, wr_en;
	logic out_rdy;
} ext;

logic [1:0] count; 											// To count valid register address	
logic spike_d1, spike_d2;										// Uart tx ready signals															
logic [UART_DATA_LEN-1:0] led_data_reg;

// Recieving value from PC 
uart_rx #(.CLKS_PER_BIT(87)) uart_rx(						// Note: If there is a weak blinking issue, check clk/bits 
	.i_Clock(clk),
	.i_Rx_Serial(rx_din),									// 1 byte input from PC
	.o_Rx_Byte(rx.dout),									// 8 bits to [7:0] rx_dout
	.o_Rx_DV(rx.rdy));										// rx done signal: tells when rx_dout is finished

always @(posedge clk)										// Control led by the cmd 
	if (reset) led_data_reg <= '0;
	else for (int k=1; k<5; k++) 
			if (ext.en==0 & rx.dout == k) 
				for (int i=0; i<UART_DATA_LEN; i++) begin
					if (i==k) led_data_reg[i] = 1;				
					else led_data_reg[i] = 0;
				end			
assign led = led_data_reg;

always @(posedge clk)
	if (reset) begin											
		sys_en 			<= '0;							// System enable signal
		fifo_rd 		<= '0;							// Fifo read signal
		ext.en 			<= '0;							// External read or write enable signal	
	end
	else if (rx.rdy) begin
		if (ext.en == 0) begin
			sys_en <= 1;	
			if (rx.dout<2) fifo_rd <= 1;
			else begin
				ext.en <= 1;							// External access enabling
				if (rx.dout==2) 		ext.wr_en <= 1;	// External write
		 		else if (rx.dout==3)	ext.rd_en <= 1;	// External read
		 	end
		end
		else if (ext.en) begin
		 	if (ext.rd_en) begin		
				ext.addr 		<= rx.dout;
				ext.out_rdy		<= 1;
				if (ext.out_rdy) begin
					ext_rd_addr <= ext.addr;
					ext_req 	<= 1;
				end
			end
			else if (ext.wr_en) begin
				ext.addr <= rx.dout;
				ext_req	 <= 2;
			end	
		end			
	end

// ---------------------------------------------------------------------------------------------
uart_tx #(.CLKS_PER_BIT(87)) uart_tx(
	.i_Clock(clk),									// Clock
	.i_Tx_DV(tx.dv),								// Start signal sending data to PC
	.i_Tx_Byte(tx.din),								// 8 bit data to send
	.o_Tx_Active(tx.active),				
	.o_Tx_Serial(tx_dout),							// PC recieves 1 byte data
	.o_Tx_Done(tx.done));

always @(posedge clk) begin							// Only for the first part of fifo_out
	spike_d1 <= spike;
	spike_d2 <= spike_d1;
end
assign tx.dv = (spike_d2) ? spike_d2 : ((tx.din_rdy_d2) ? tx.din_rdy_d2 : 0);

always @(posedge clk) begin
	tx.done_d1 	<= tx.done;
	tx.done_d2 	<= tx.done_d1;
end

assign tx.din_rdy = (tx.done&~tx.done_d1) ? ((count<2) ? 1 : 0) : 0;				// spike for 2nd and 3rd slice

always @(posedge clk) begin
	tx.din_rdy_d1 <= tx.din_rdy;
	tx.din_rdy_d2 <= tx.din_rdy_d1;
end

// counter
always @(posedge clk)
	if (reset) 							count <= 2;  
	else if (spike) 					count <= 1;
	else if (tx.din_rdy & count > 0) 	count <= count - 1'b1;
	else if (tx.din_rdy & count == 0) 	count <= 2;

// Internal read
always @(posedge clk)
	if (spike_d1) tx.din_reg <= fifo_dout;

always @(posedge clk)
	if (reset) 				tx.din <= '0;
	else if (spike_d1) 		tx.din <= tx.din_reg[23:16];
	else if (tx.din_rdy) 	tx.din <= tx.din_reg[count*UART_DATA_LEN +: UART_DATA_LEN];

initial begin
 	sys_en = '0;
 	count = 2;
	fifo_rd = '0;
	ext_req = '0;
	ext.en = '0;
	ext.rd_en = '0;
	ext.wr_en = '0;
	ext.addr = '0;
	ext.out_rdy = '0;
	spike_d1 = '0;
	spike_d2 = '0;
	tx.done_d1 = '0;
	tx.done_d2 = '0;
	tx.din = '0;
	tx.din_rdy_d1 = '0;
	tx.din_rdy_d2 = '0;
	tx.din_reg = '0;
	led_data_reg = '0;
end
endmodule
