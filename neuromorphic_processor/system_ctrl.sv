`timescale 1ns / 1ps
module system_ctrl #(parameter TS_WIDTH=16, NEURON_NO=256, UART_DATA_LEN=8, UART_CYC=3, NEURON_LEN= 13)
	(input logic 	clk, reset,
	 input logic 	rx_dv, rx_data,	 
	 output logic 	sys_en,
	 output logic 	fifo_rd,
	 // output logic 	[UART_DATA_LEN-1:0] led,
	 output logic 	[1:0] ext_req,
	 output logic	[$clog2(NEURON_NO)-1:0] ext_rd_addr, ext_wr_addr,
	 input logic    [NEURON_LEN-1:0] ext_dout, 
	 output logic   [NEURON_LEN-1:0] ext_din,
	 input logic 	spike,
	 input logic 	[TS_WIDTH+$clog2(NEURON_NO)-1:0] fifo_dout);

struct {logic en;
		logic [$clog2(NEURON_NO)-1:0] addr;		
		logic rd_en, wr_en;
		logic out_rdy;
		} ext;

logic [1:0] count; 						// count valid register address	
logic spike_d1, spike_d2;				// 															
logic [UART_DATA_LEN-1:0] led_data_reg;

typedef enum logic [1:0] {idel_s,  wract1_s, wract2_s} state_t;
state_t state_reg;

always @(posedge clk)
	if (reset) begin											
		sys_en 			<= '0;							// System enable signal
		ext.en 			<= '0;							// External read or write enable signal	
	end
	else if (rx_dv) begin								// ready to receive data from PC
		if (rx_data == 1) begin
			sys_en <= 1;	
		end
		else if (ext.en) begin
		 	if (ext.rd_en) begin		
				ext.addr 		<= rx_data;
				ext.out_rdy		<= 1;
				if (ext.out_rdy) begin
					ext_rd_addr <= ext.addr;
					ext_req 	<= 1;
				end
			end
			else if (ext.wr_en) begin
				ext.addr <= rx_data;
				ext_req	 <= 2;
			end	
		end			
	end

// always @(posedge clk)
// 	if (reset) state_reg <= idel_s;
// 	else if (rx.dv) begin
// 		idel_s:
// 			case (rx.data)
// 				cmd: begin 
// 					state_reg <= scroll_s;
// 					sys_en <= 1;
// 				default: begin
// 					state_reg <= idel_s;
// 					sys_en <= 0;
// 				end
// 			endcase
// 		scroll_s:

// 	end

// always @(posedge clk) begin
// 	if(reset) begin
// 		state_reg <= idle_s;
// 	end
// 	else if (rx.dv) begin
// 		case (state_reg)
// 			idle_s:
// 				case (rx.data)
// 					cmd.wract: begin
// 						state_reg <= wract1_s;
// 						sys_en <= 1;
// 					end
// 					default: begin
// 						state_reg <= idle_s;
// 						sys_en <= 0;
// 					end
// 				endcase

// 	 		wract1_s: begin
// 	 			fifo_wr <= 0;
// 				case (rx.data)
// 					cmd_idle: begin
// 						state_reg <= idle_s;
// 						sys_en <= 0;
// 					end
// 					default: begin
// 						state_reg <= wract2_s;
// 						fifo_din[15:8] <= rx_data;
// 					end
// 				endcase
// 			end

// 			wract2_s:
// 				case (rx.data)
// 					cmd_idle: begin
// 						state_reg <= idle_s;
// 						sys_en <= 0;
// 					end
// 					default: begin
// 						state_reg <= wract1_s;
// 						fifo_din[7:0] <= rx_data;
// 						fifo_wr <= ~fifo_full;
// 					end
// 				endcase
// 		endcase
// 	end
// end


// always @(posedge clk) begin							// Only for the first part of fifo_out
// 	spike_d1 <= spike;
// 	spike_d2 <= spike_d1;
// end
// assign tx.dv = (spike_d2) ? spike_d2 : ((tx.din_rdy_d2) ? tx.din_rdy_d2 : 0);

// always @(posedge clk) begin
// 	tx.done_d1 	<= tx.done;
// 	tx.done_d2 	<= tx.done_d1;
// end

// assign tx.din_rdy = (tx.done&~tx.done_d1) ? ((count<2) ? 1 : 0) : 0;				// spike for 2nd and 3rd slice

// always @(posedge clk) begin
// 	tx.din_rdy_d1 <= tx.din_rdy;
// 	tx.din_rdy_d2 <= tx.din_rdy_d1;
// end

// // counter
// always @(posedge clk)
// 	if (reset) 							count <= 2;  
// 	else if (spike) 					count <= 1;
// 	else if (tx.din_rdy & count > 0) 	count <= count - 1'b1;
// 	else if (tx.din_rdy & count == 0) 	count <= 2;

// // Internal read
// always @(posedge clk)
// 	if (spike_d1) tx.din_reg <= fifo_dout;

// always @(posedge clk)
// 	if (reset) 				tx.din <= '0;
// 	else if (spike_d1) 		tx.din <= tx.din_reg[23:16];
// 	else if (tx.din_rdy) 	tx.din <= tx.din_reg[count*UART_DATA_LEN +: UART_DATA_LEN];

initial begin
 	sys_en = '0;
 	count = 2;
	fifo_rd = '0;
	ext_req = '0;
	ext.en = '0;
	ext.rd_en = '0;
	ext.wr_en = '0;
	ext.addr = '0;
	ext_rd_addr = '0;
	ext_wr_addr = '0;
	ext.out_rdy = '0;
	spike_d1 = '0;
	spike_d2 = '0;
	ext_din = '0;
end
endmodule





// always @(posedge clk)										// Control led by the data 
// 	if (reset) led_cmd_reg <= '0;
// 	else for (int k=1; k<5; k++) 
// 			if (ext.en==0 & rx.data == k) 
// 				for (int i=0; i<UART_DATA_LEN; i++) begin
// 					if (i==k) led_cmd_reg[i] = 1;				
// 					else led_cmd_reg[i] = 0;
// 				end			
// assign led = led_cmd_reg;

// always @(posedge clk)
// 	if (reset) begin											
// 		sys_en 			<= '0;							// System enable signal
// 		fifo_rd 		<= '0;							// Fifo read signal
// 		ext.en 			<= '0;							// External read or write enable signal	
// 	end
// 	else if (rx.dv) begin								// ready to receive data from PC
// 		if (ext.en == 0) begin
// 			sys_en <= 1;	
// 			if (rx.data<2) fifo_rd <= 1;
// 			else if (rx.data<4) begin
// 				ext.en <= 1;							// External access enabling
// 				if (rx.data==2) 		ext.wr_en <= 1;	// External write
// 		 		else if (rx.data==3)	ext.rd_en <= 1;	// External read
// 		 	end
// 		 	else if (rx.data==4) fifo_rd <= 0;			// Stoping FIFO read
// 		 	else if (rx.data==5) fifo_rd <= 1;			// Start/restart FIFO read

// 		end
// 		else if (ext.en) begin
// 		 	if (ext.rd_en) begin		
// 				ext.addr 		<= rx.data;
// 				ext.out_rdy		<= 1;
// 				if (ext.out_rdy) begin
// 					ext_rd_addr <= ext.addr;
// 					ext_req 	<= 1;
// 				end
// 			end
// 			else if (ext.wr_en) begin
// 				ext.addr <= rx.data;
// 				ext_req	 <= 2;
// 			end	
// 		end			
// 	end

