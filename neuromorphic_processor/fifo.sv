`timescale 1ns / 1ps
module fifo #(parameter FIFO_MEM_LEN=24, FIFO_MEM_NO = 8) (
	input logic clk, reset,
	input logic en,
	input logic rd, wr,									// Read and write commands
	input logic [FIFO_MEM_LEN-1:0] fifo_data_in,
	output logic fifo_data_out,
	output logic empty, full); 							// Fifo memory empty and full flags

logic [FIFO_MEM_LEN-1:0] fifo_mem [2**FIFO_MEM_NO-1:0];	
logic wr_en, rd_en;
logic [FIFO_MEM_NO-1:0] wr_ptr, rd_ptr;

assign wr_en = wr & ~full;

always @(posedge clk)
	if (reset) wr_ptr <= 0;
	else if (wr_en) wr_ptr <= wr_ptr + 1'b1;

always @(posedge clk)
	if (wr_en) fifo_mem[wr_ptr] = fifo_data_in;

assign re_en = rd & ~empty;

always @(posedge clk)
	if (reset) fifo_data_out <= 0;
	else if (rd_en) fifo_data_out <= fifo_mem[rd_ptr];

initial begin
	for (int i=0; i<2**FIFO_MEM_NO; i++) begin
		fifo_mem[i] = 0;
	end

end

endmodule
