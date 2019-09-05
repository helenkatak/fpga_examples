`timescale 1ns / 1ps
module pc_comm #(parameter INPUT_LEN=24, OUTPUT_LEN=8)
	(input logic clk, reset,
	 input logic chunk_en,
	 input logic [INPUT_LEN-1:0] data_in,						// Note: Input data should not be longer than 3 clk cycle
	 output logic [OUTPUT_LEN-1:0] data_out);

localparam DATA_REG_LEN = INPUT_LEN/OUTPUT_LEN;

logic [INPUT_LEN-1:0] data_in_tmp; 
logic chunk_rd_flag;
logic [OUTPUT_LEN-1:0] data_reg [DATA_REG_LEN-1:0];				// Data register							

always @(posedge clk)
	data_in_tmp <= data_in;

always @(posedge clk)
	if (reset) chunk_rd_flag <= 0;
	else chunk_rd_flag <= (data_in_tmp != data_in) ? 1 : 0; 	// Chunk read flag goes high only when the input value is different from previous value

always @(posedge clk)	
	if (reset) begin
		data_reg[0] <= 0;
		data_reg[1] <= 0;
		data_reg[2] <= 0;
	end
	else if (chunk_rd_flag) begin 
		data_reg[0] <= data_in[23:16];							// First part of time stamp
		data_reg[1] <= data_in[15:8];							// Second part of time stamp
		data_reg[2] <= data_in[7:0];							// Spiking neuron address
	end

uart_rx #(.CLKS_PER_BIT(868)) uart_rx (
  	.i_Clock(clk),
  	.i_Rx_Serial(),
	.o_Rx_DV(),
	.o_Rx_Byte());
    
// uart_tx #(.CLKS_PER_BIT(868)) uart_tx (
// 	.i_Clock(),
//   	.i_Tx_DV(),
//   	.i_Tx_Byte(), 
//    	.o_Tx_Active(),
//   	.o_Tx_Serial(),
//    	.o_Tx_Done()); 

initial begin
	for (int i=0; i<OUTPUT_LEN; i++) begin
		data_reg[i] = 0;
	end
	data_in_tmp <= 0;
	chunk_rd_flag = 0;
end
endmodule
