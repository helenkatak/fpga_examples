`timescale 1ns / 1ps
module fifo #(parameter FIFO_MEM_LEN=24, FIFO_MEM_NO=8) (
	input logic clk, reset, 
	input logic en,
	input logic rd, wr,									// Read and write commands
	input logic [FIFO_MEM_LEN-1:0] fifo_data_in,
	output logic [FIFO_MEM_LEN-1:0] fifo_data_out,
	output logic empty, full); 							// Fifo memory empty and full flags

logic [FIFO_MEM_LEN-1:0] fifo_mem [2**FIFO_MEM_NO-1:0];	
logic  rd_en;
logic [FIFO_MEM_NO-1:0] wr_ptr, rd_ptr, ptr_dist;		// Write pointer, read pointer and disatance between pointers
logic wr_ptr_cond, rd_ptr_cond, full_cond;				// Write and read pointer 1 cycle condition
														// Note: it flips the bit when it reaches highest
assign ptr_dist = (reset) ? 0 : wr_ptr - rd_ptr;

assign full_cond = (wr_ptr_cond^rd_ptr_cond);				// Full condition: when wr_ptr and rd_ptr is in the same cycle
assign full = (ptr_dist == 2**FIFO_MEM_NO-1) & full_cond;

// assign wr_en = wr & ~full;								// Write enable 

always @(posedge clk)
	if (reset) wr_ptr <= 0;
	else if (wr & ~full) wr_ptr <= (wr_ptr == 2**FIFO_MEM_NO-1) ? 0 : wr_ptr + 1'b1;

// Pointer condition flips every time when write pointer reaches the highest address
always @(posedge clk)
	if (reset) wr_ptr_cond <= 0;
	else if (wr_ptr == 2**FIFO_MEM_NO-1) wr_ptr_cond <= ~wr_ptr_cond;

always @(posedge clk)
	if (reset) 	
		for (int i=0; i<2**FIFO_MEM_NO; i++) begin
			fifo_mem[i] = 0;
		end
	else if (wr & ~full) fifo_mem[wr_ptr] = fifo_data_in;

assign empty = (ptr_dist == 0);
assign rd_en = rd & ~empty;								// Read enable

always @(posedge clk)
	if (reset) fifo_data_out <= 0;
	else if (rd_en) fifo_data_out <= fifo_mem[rd_ptr];

always @(posedge clk)
	if (reset) rd_ptr <= 0;
	else if (rd_en) rd_ptr <= (rd_ptr == 2**FIFO_MEM_NO-1) ? 0 : rd_ptr + 1'b1;

always @(posedge clk)
	if (reset) rd_ptr_cond <= 0;
	else if (rd_ptr == 2**FIFO_MEM_NO-1) rd_ptr_cond <= ~rd_ptr_cond;

initial begin
	for (int i=0; i<2**FIFO_MEM_NO; i++) begin
		fifo_mem[i] = 0;
	end
	rd_ptr = 0;
	wr_ptr = 0;
	fifo_data_out = 0;
	wr_ptr_cond = 0;
	rd_ptr_cond = 0;
end
endmodule
