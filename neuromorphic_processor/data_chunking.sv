`timescale 1ns / 1ps
module data_chunking #(parameter INPUT_LEN=24, OUTPUT_LEN=8)
	(input logic clk, reset,
	 input logic [INPUT_LEN-1:0] data_in,				// Note: Input data should not be longer than 3 clk cycle
	 output logic out_val, 								// Valid output flag
	 output logic [OUTPUT_LEN-1:0] data_out);

localparam DATA_REG_LEN = INPUT_LEN/OUTPUT_LEN;

logic [OUTPUT_LEN-1:0] data_reg [DATA_REG_LEN-1:0];		// Data register
logic [1:0] out_addr;									// Data register output address

always @(posedge clk)	
	if (reset) begin
		data_reg[0] <= 0;
		data_reg[1] <= 0;
		data_reg[2] <= 0;
	end
	else if (data_in) begin 
		data_reg[0] <= data_in[23:16];
		data_reg[1] <= data_in[15:8];
		data_reg[2] <= data_in[7:0];
	end

always @(posedge clk)
	if (reset) out_val <= 0;
	else if (data_in) out_val <= 1'b1;
	else out_val <= 1'b0;

always @(posedge clk)
	if (reset) out_addr <= 0;
	else out_addr <= (out_val) ? out_addr + 1'b1 : ((out_addr > 2'b00 & out_addr < 2'b10 ) ? out_addr + 1'b1 : 0);	// Valid value flag

assign data_out = (out_val) ? data_reg[out_addr] : ((out_addr == 0) ? 0 : data_reg[out_addr]);

endmodule
