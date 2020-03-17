`timescale 1ns / 1ps
module fifo #(parameter FIFO_MEM_LEN=24, FIFO_MEM_NO=3) (
	input logic clk, reset, 
	input logic spike, fifo_rd_en,				
	input logic [FIFO_MEM_LEN-1:0] fifo_din,
	output logic full, empty,			// FIFO memory empty and full flags
	output logic [FIFO_MEM_LEN-1:0] fifo_dout); 	

struct {logic en, en_tmp;
		logic [FIFO_MEM_NO-1:0] ptr;
		} wr;											

struct {logic en;	
		logic [FIFO_MEM_NO-1:0] ptr;					
		} rd;

logic fifo_rd_en_d;
logic spike_d;
(*ram_style = "distributed"*) logic [FIFO_MEM_LEN-1:0] fifo_mem [2**FIFO_MEM_NO-1:0];	

always @(posedge clk) 
	spike_d <= spike;

// ------------------ WRITING -----------------------------------------------
always @(posedge clk)
	if (reset) wr.ptr <= 0;
	else if (spike_d) wr.ptr <= full ? wr.ptr : wr.ptr + 1'b1;	// Write pointer 

assign full = (wr.ptr==rd.ptr+2**FIFO_MEM_NO+1 | wr.ptr==rd.ptr-2**FIFO_MEM_NO+1);

assign wr.en = spike_d & ~full;									// Write enable signal
	
always @(posedge clk)											
	if (wr.en) fifo_mem[wr.ptr[FIFO_MEM_NO-1:0]] <= fifo_din;	// Writing

// ------------------ READING -----------------------------------------------
always @(posedge clk)											
 	wr.en_tmp <= wr.en;											// Write enable signal delay

assign rd.en = wr.en_tmp & ~empty;								// Read enable signal

always @(posedge clk)
	fifo_rd_en_d <= fifo_rd_en;									// tx ready signal 							

always @(posedge clk)
	if (reset) rd.ptr <= 2**FIFO_MEM_NO-1;
	else if (fifo_rd_en & ~empty) rd.ptr <= rd.ptr + 1'b1;		// Read pointer 
	
assign empty = (wr.ptr == rd.ptr);								// FIFO empty

always @(posedge clk)											
	if (reset) fifo_dout <= 0;									// Reading
	else if (rd.en | fifo_rd_en_d) fifo_dout <= fifo_mem[rd.ptr[FIFO_MEM_NO-1:0]];

initial begin
	for (int i=0; i<2**FIFO_MEM_NO; i++) begin
		fifo_mem[i] = 0;
	end
	rd.ptr = '0;
	wr.ptr = '0;
	wr.en_tmp = '0;
	fifo_dout = '0;
	fifo_rd_en_d = '0;
	spike_d= '0;
end
endmodule
