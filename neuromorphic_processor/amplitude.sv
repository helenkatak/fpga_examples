`timescale 1ns / 1ps
module amplitude #(parameter NEURON_NO=2**8, AMPL_WID=20, MU_LEN=32) 
	(input logic clk, reset,
	 input logic sp_in, sp_out,
	 input logic [MU_LEN-1:0] ker_a, ker_b,
	 input logic wr_en,
	 input logic [$clog2(NEURON_NO)-1:0] wr_addr,
	 output logic [AMPL_WID-1:0] ampl_a_out, ampl_b_out);

logic [$clog2(NEURON_NO)-1:0] wr_addr_d, wr_addr_dd;
logic [AMPL_WID-1:0] ampl_a_ram [NEURON_NO-1:0];			// amplitude ram
logic [AMPL_WID-1:0] ampl_b_ram [NEURON_NO-1:0];			// amplitude ram
logic wr_en_d, wr_en_dd;

always @(posedge clk) begin									// writing enable signal
	wr_en_d <= wr_en;
	wr_en_dd <= wr_en_d;
end

always @(posedge clk) begin								
	wr_addr_d <= wr_addr;									// writting address sginal
	wr_addr_dd <= wr_addr_d;
end

assign ampl_a_out = (wr_en) ? ampl_a_ram[wr_addr] : 0;		// ampl ram writing	
assign ampl_b_out = (wr_en) ? ampl_b_ram[wr_addr] : 0;		// ampl ram writing	

always @(posedge clk)										
	if (wr_en_d | wr_en_dd) begin									
		if (sp_in) begin 
			ampl_a_ram[wr_addr_d] <= ker_a;				// ampl_a_ram update by spike in signal
			ampl_b_ram[wr_addr_d] <= ker_b;				
		end
		else if (sp_out) begin
			ampl_a_ram[wr_addr_dd] <= 0; 					// ampl_a_ram reset by spike out signal
			ampl_b_ram[wr_addr_dd] <= 0; 
		end
		else begin
			ampl_a_ram[wr_addr_d] <= ampl_a_ram[wr_addr_d];	
			ampl_b_ram[wr_addr_d] <= ampl_b_ram[wr_addr_d];	
		end
	end

initial begin
  	for (int i=0; i<NEURON_NO; i++) begin						
		ampl_a_ram[i] = 0; 	
		ampl_b_ram[i] = 0;
	end
	wr_addr_d = '0;
	wr_addr_dd = '0;
	wr_en_d = '0;
	wr_en_dd = '0;
end
endmodule
