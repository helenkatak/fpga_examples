`timescale 1ns / 1ps
module lfsr #(parameter LFSR_LEN = 16)
	(input logic clk, reset,
	 input logic lfsr_en,
	 output logic [LFSR_LEN-1:0] lfsr_out);

logic [LFSR_LEN-1:0] lfsr_reg; 				// lfsr register

always @(posedge clk) begin
	if (reset | lfsr_en == 1'b0) begin
		lfsr_reg[0] <= 1'b1;
		for (int i=1; i<LFSR_LEN; i++) begin
			lfsr_reg[i] <= 1'b0;
		end
	end
	else if (lfsr_en == 1'b1) begin
		lfsr_reg[0] <= lfsr_reg[1]^lfsr_reg[2]^lfsr_reg[4]^lfsr_reg[15];
		for (int i=1; i<LFSR_LEN; i++) begin
			lfsr_reg[i] <= lfsr_reg[i-1];
		end
	end
end

assign lfsr_out[0] = lfsr_reg[0];
assign lfsr_out[1] = lfsr_reg[15];
assign lfsr_out[2] = lfsr_reg[2];
assign lfsr_out[3] = lfsr_reg[14];

assign lfsr_out[4] = lfsr_reg[10];
assign lfsr_out[5] = lfsr_reg[5];
assign lfsr_out[6] = lfsr_reg[13];
assign lfsr_out[7] = lfsr_reg[7];

assign lfsr_out[8] = lfsr_reg[8];
assign lfsr_out[9] = lfsr_reg[9];
assign lfsr_out[10] = lfsr_reg[4];
assign lfsr_out[11] = lfsr_reg[11];

assign lfsr_out[12] = lfsr_reg[12];
assign lfsr_out[13] = lfsr_reg[6];
assign lfsr_out[14] = lfsr_reg[3];
assign lfsr_out[15] = lfsr_reg[1];

initial begin
	lfsr_reg[0] = 1'b1;
	for (int i=1; i<LFSR_LEN; i++) begin
		lfsr_reg[i] = 1'b0;
	end

end
endmodule
