`timescale 1ns / 1ps
module amplitude #(parameter NEURON_NO=2**8, AMPL_WID=20, MU_LEN=32) 
	(input logic clk, reset,
	 input logic wr_en,
	 input logic sp_in,
	 input logic sp_out,
	 input logic [MU_LEN-1:0] mu_in,
	 input logic [$clog2(NEURON_NO)-1:0] wr_addr,
	 output logic [AMPL_WID-1:0] ampl_out);

logic [$clog2(NEURON_NO)-1:0] wr_addr_d, wr_addr_dd;
logic [AMPL_WID-1:0] ampl_ram [NEURON_NO-1:0];			// amplitude ram
logic wr_en_d, wr_en_dd;

always @(posedge clk) begin								// writing enable signal
	wr_en_d <= wr_en;
	wr_en_dd <= wr_en_d;
end

always @(posedge clk) begin								
	wr_addr_d <= wr_addr;								// writting address sginal
	wr_addr_dd <= wr_addr_d;
end

assign ampl_out = (wr_en) ? ampl_ram[wr_addr] : 0;		// ampl ram writing	

always @(posedge clk)										
	if (wr_en_d | wr_en_dd) begin									
		if (sp_in) ampl_ram[wr_addr_d] <= mu_in;		// ampl_ram update by spike in signal
		else if (sp_out) ampl_ram[wr_addr_dd] <= 0; 	// ampl_ram reset by spike out signal
		else ampl_ram[wr_addr_d] <= ampl_ram[wr_addr_d];	
	end

initial begin
  	for (int i=0; i<NEURON_NO; i++) 						
		ampl_ram[i] = 0; 	

	wr_addr_d = '0;
	wr_addr_dd = '0;
	wr_en_d = '0;
	wr_en_dd = '0;
end
endmodule
