`timescale 1ns / 1ps
module fifo #(parameter FIFO_MEM_LEN=24, FIFO_MEM_NO=8) (
	input logic clk, reset, 
	input logic sys_en,
	input logic rd, wr,										// Read and write commands
	input logic [FIFO_MEM_LEN-1:0] fifo_din,
	output logic fifo_full, fifo_empty,
	output logic [FIFO_MEM_LEN-1:0] fifo_dout); 			// Fifo memory empty and full flags

logic [FIFO_MEM_LEN-1:0] fifo_mem [2**FIFO_MEM_NO-1:0];	
logic rd_en, wr_en, wr_en_d, wr_d, rd_en_d, rd_d;
logic [FIFO_MEM_NO:0] wr_ptr, rd_ptr;				// Write pointer, read pointer and distance between pointers
logic [FIFO_MEM_NO-1:0] wr_ptr_;
logic cyc_cond;												// Write and read pointer 1 cycle condition

// Pointer cycle condition
assign cyc_cond = wr_ptr[FIFO_MEM_NO]^rd_ptr[FIFO_MEM_NO];


// --------------------------------------------------------------------------
// ------------------ WRITING -----------------------------------------------

// Write pointer from 0 to maximum and again 0 
always @(posedge clk)
	if (reset) wr_ptr <= 0;
	else if (wr) wr_ptr <= (wr_ptr==rd_ptr+2**FIFO_MEM_NO-1 | wr_ptr==rd_ptr-2**FIFO_MEM_NO) ? wr_ptr: wr_ptr + 1'b1;

// Delaying write signal which is spike signal
always @(posedge clk)
	wr_d <= wr;

// Write enable signal
assign fifo_full = cyc_cond & (wr_ptr==rd_ptr+2**FIFO_MEM_NO-1 | wr_ptr==rd_ptr-2**FIFO_MEM_NO);
assign wr_en = wr_d & ~fifo_full;

// assign wr_en = wr_d & ((~cyc_cond & wr_ptr>rd_ptr) | (cyc_cond & rd_ptr>wr_ptr)) ; 

// Writing
always @(posedge clk)
	if (wr_en) fifo_mem[wr_ptr_] <= fifo_din;
		//if (wr_ptr!=0) fifo_mem[wr_ptr-1] <= fifo_din;
		//else if (wr_ptr==0) fifo_mem[2**FIFO_MEM_NO-1] <= fifo_din;
assign wr_ptr_ = (wr_ptr[FIFO_MEM_NO-1:0]-1!=0) ? wr_ptr[FIFO_MEM_NO-1:0]-1 : 0;


// --------------------------------------------------------------------------
// ------------------ READING -----------------------------------------------

// Read enable signal
assign fifo_empty = ~cyc_cond & (wr_ptr == rd_ptr);
assign rd_en = rd & ~fifo_empty;
// assign rd_en = rd & (~cyc_cond ? wr_ptr>rd_ptr : rd_ptr>wr_ptr);							

always @(posedge clk)
	rd_en_d <= rd_en;

assign rd_d = rd_en & rd_en_d;

// Read pointer from 0 to maximum and again 0
always @(posedge clk)
	if (reset) rd_ptr <= 0;
	else if (rd_d) rd_ptr <= rd_ptr + 1'b1;

// Reading
always @(posedge clk)
	if (reset) fifo_dout <= 0;
	else if (rd_d) fifo_dout <= fifo_mem[rd_ptr[FIFO_MEM_NO-1:0]];

initial begin
	for (int i=0; i<2**FIFO_MEM_NO; i++) begin
		fifo_mem[i] = 0;
	end
	rd_ptr = 0;
	wr_ptr = 0;
	fifo_dout = 0;
	wr_d = 0;
	rd_en_d = 0;
end
endmodule
