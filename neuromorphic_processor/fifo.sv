`timescale 1ns / 1ps
module fifo #(parameter FIFO_MEM_LEN=24, FIFO_MEM_NO=5) (
	input logic clk, reset, 
	input logic spike, fifo_rd_en,				
	input logic [FIFO_MEM_LEN-1:0] fifo_din,
	output logic full, empty,					// FIFO memory empty and full flags
	output logic [FIFO_MEM_LEN-1:0] fifo_dout); 	

struct {										// write signals
logic spike_d, en;
logic [FIFO_MEM_NO:0] ptr;
logic [FIFO_MEM_NO-1:0] ptr_;
} wr;											

struct {										// read signals 
logic en_tmp, en_tmp_d, en;	
logic [FIFO_MEM_NO:0] ptr;					
} rd;

logic cyc_cond;									// Write and read pointer 1 cycle condition
logic [FIFO_MEM_LEN-1:0] fifo_mem [2**FIFO_MEM_NO-1:0];	

assign cyc_cond = wr.ptr[FIFO_MEM_NO]^rd.ptr[FIFO_MEM_NO]; // Pointer cycle condition


// ------------------ WRITING -----------------------------------------------
always @(posedge clk)
	if (reset) wr.ptr <= 2**FIFO_MEM_NO-1;
	else if (spike) 
		wr.ptr <= (wr.ptr==rd.ptr+2**FIFO_MEM_NO-1 | wr.ptr==rd.ptr-2**FIFO_MEM_NO) ? wr.ptr: wr.ptr + 1'b1;

always @(posedge clk) wr.spike_d <= spike;

// Write enable signal
assign full = cyc_cond & (wr.ptr==rd.ptr+2**FIFO_MEM_NO-1 | wr.ptr==rd.ptr-2**FIFO_MEM_NO);
assign wr.en = wr.spike_d & ~full;

// assign wr.en = wr.spike_d;& ((~cyc_cond & wr.ptr>rd.ptr) | (cyc_cond & rd.ptr>wr.ptr)) ; 

	// Writing
always @(posedge clk)
	if (wr.en) fifo_mem[wr.ptr[FIFO_MEM_NO-1:0]] <= fifo_din;
		//if (wr.ptr!=0) fifo_mem[wr.ptr-1] <= fifo_din;
		//else if (wr.ptr==0) fifo_mem[2**FIFO_MEM_NO-1] <= fifo_din;
assign wr.ptr_ = (wr.ptr[FIFO_MEM_NO-1:0]-1!=0) ? wr.ptr[FIFO_MEM_NO-1:0]-1 : 0;

// ------------------ READING -----------------------------------------------

	// Read enable signal
assign empty = ~cyc_cond & (wr.ptr == rd.ptr);
assign rd.en_tmp = fifo_rd_en & ~empty;
// assign rd.en_tmp = fifo_rd_en & (~cyc_cond ? wr.ptr>rd.ptr : rd.ptr>wr.ptr);							

always @(posedge clk)
	rd.en_tmp_d <= rd.en_tmp;

assign rd.en = rd.en_tmp & rd.en_tmp_d;

	// Read pointer from 0 to maximum and again 0
always @(posedge clk)
	if (reset) rd.ptr <= 2**FIFO_MEM_NO-1;
	else if (rd.en) rd.ptr <= rd.ptr + 1'b1;

	// Reading
always @(posedge clk)
	if (reset) fifo_dout <= 0;
	else if (rd.en) fifo_dout <= fifo_mem[rd.ptr[FIFO_MEM_NO-1:0]];

initial begin
	for (int i=0; i<2**FIFO_MEM_NO; i++) begin
		fifo_mem[i] = 0;
	end
	rd.ptr = 2**FIFO_MEM_NO-1;
	wr.ptr = 2**FIFO_MEM_NO-1;
	fifo_dout = 0;
	wr.spike_d= 0;
	rd.en_tmp_d = 0;
end
endmodule
