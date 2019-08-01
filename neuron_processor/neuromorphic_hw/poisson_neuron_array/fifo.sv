`timescale 1ns / 1ps
module fifo #(parameter DATA_WIDTH=16, ADDR_WIDTH=7)
// DATA_WIDTH - width of data to be stored in FIFO
// ADDR_WIDTH - defines FIFO depth
	(input logic clk, reset,
	 input logic wr, rd,							// write and read commands
	 input logic [DATA_WIDTH-1:0] data_in,
	 output logic fifo_full, fifo_empty,			// full and empty flags
	 output logic [DATA_WIDTH-1:0] data_out);

// FIFO RAM
logic [DATA_WIDTH-1:0] fifo_mem [2**ADDR_WIDTH-1:0];
logic wr_en, rd_en;									// write and read enable
logic [ADDR_WIDTH-1:0] wr_ptr, rd_ptr;				// RAM read and write addresses

always @(posedge clk)
	if (wr_en) fifo_mem[wr_ptr] <= data_in;

always @(posedge clk)
	if (reset) data_out <= 0;
	else if (rd_en) data_out <= fifo_mem[rd_ptr];

// Flags
logic [ADDR_WIDTH:0] ptr_dist;						// distance between read and write pointers

always @(posedge clk)
	if (reset) ptr_dist <= 0;
	else if (wr_en^rd_en) ptr_dist <= rd_en ? ptr_dist - 1'b1 : ptr_dist + 1'b1;

assign fifo_empty = ptr_dist == 0;
assign fifo_full = ptr_dist == 2**ADDR_WIDTH;		// fifo is full when we wrap around our address space

// Pointers
assign wr_en = ~fifo_full & wr;
assign rd_en = ~fifo_empty & rd;

always @(posedge clk)
	if (reset) wr_ptr <= 0;
	else if (wr_en) wr_ptr <= wr_ptr + 1'b1;

always @(posedge clk)
	if (reset) rd_ptr <= 0;
	else if (rd_en) rd_ptr <= rd_ptr + 1'b1;

// Empty  : Kate added, and need to be checked 
// always @(posedge clk)
// 	empty_delay <= fifo_empty;
// 	fifo_empty_out <= fifo_empty|empty_delay;

endmodule
