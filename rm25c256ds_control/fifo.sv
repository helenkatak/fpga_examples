`timescale 1ns / 1ps
module fifo #(parameter FIFO_NO=4, SER_LEN=8) 
	(input logic clk, reset, 
	 input logic din_rdy, 
	 input logic [SER_LEN-1:0] din,
	 input logic tx_active, tx_done,
	 output logic full, empty,
	 output logic rd_rdy,
	 output logic [SER_LEN-1:0] dout); 	

logic wr_en, rd_en;
logic [FIFO_NO:0] wr_ptr, rd_ptr;
logic tx_done_d;
(*ram_style = "distributed"*) logic [SER_LEN-1:0] mem[2**FIFO_NO-1:0];	

always @(posedge clk)									// Write pointer 
	if (reset) wr_ptr <= 0;
	else if (din_rdy) wr_ptr <= (~full) ? wr_ptr+1 : wr_ptr;	

assign full = (rd_ptr[FIFO_NO-1:0]==wr_ptr[FIFO_NO-1:0]) & (wr_ptr[FIFO_NO]!=rd_ptr[FIFO_NO]); //(wr_ptr==rd_ptr+2**FIFO_NO+1 | wr_ptr==rd_ptr-2**FIFO_NO+1);

assign wr_en = din_rdy & ~full; 						// Write enable signal
	
always @(posedge clk) 									// Writing
	if (wr_en) mem[wr_ptr[FIFO_NO-1:0]] <= din;

always @(posedge clk) tx_done_d <= tx_done;

assign tx_rdy = tx_active|tx_done_d;

assign rd_en = ~tx_rdy & ~empty;							// Read enable signal

always @(posedge clk)									// Read pointer 
	if (reset) rd_ptr <= 0;
	else if (~tx_rdy) rd_ptr <= (~empty) ? rd_ptr+1 : rd_ptr;			
	
assign empty = (wr_ptr==rd_ptr);						// FIFO empty

always @(posedge clk)									// Reading		
	if (reset) dout <= 0;								
	else dout <= (rd_en) ? mem[rd_ptr[FIFO_NO-1:0]] : 0;

always @(posedge clk) rd_rdy <= rd_en;

initial begin
	for (int i=0; i<2**FIFO_NO; i++) begin
		mem[i] = 0;
	end
	rd_ptr = 0;
	wr_ptr = 0;
	dout = 0;
	rd_rdy = 0;
	tx_done_d = 0;
end
endmodule
