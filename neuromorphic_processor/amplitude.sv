`timescale 1ns / 1ps
module amplitude #(parameter NEURON_NO=2**8, AMPL_WID=20, MU_LEN=32) 
	(input logic clk, reset,
	 input logic sp_in, sp_out,
	 input logic [MU_LEN-1:0] ker_a, ker_b,
	 input logic rd_en,
	 input logic [$clog2(NEURON_NO)-1:0] rd_addr,
	 output logic [AMPL_WID-1:0] ampl_a_out, ampl_b_out);

logic [$clog2(NEURON_NO)-1:0] rd_addr_d, wr_addr, wr_addr_d, wr_addr_dd, amp_wr_addr;
(*ram_style = "distributed"*)  logic [AMPL_WID-1:0] ampl_a_ram [NEURON_NO-1:0];	// amplitude A ram
(*ram_style = "distributed"*)  logic [AMPL_WID-1:0] ampl_b_ram [NEURON_NO-1:0];	// amplitude B ram
logic wr_en, wr_en_d, wr_en_dd, sp_out_d;

always @(posedge clk) begin									// writing enable signal
	wr_en 	<= rd_en;
	wr_en_d	<= wr_en;
	wr_en_dd	<= wr_en_d;
end

always @(posedge clk) begin								
	rd_addr_d 	<= rd_addr;									// writting address sginal
	wr_addr 	<= rd_addr_d;
	wr_addr_d 	<= wr_addr;
	wr_addr_dd 	<= wr_addr_d;
end

assign ampl_a_out = (rd_en) ? ampl_a_ram[rd_addr] : 0;		// ampl ram reading	
assign ampl_b_out = (rd_en) ? ampl_b_ram[rd_addr] : 0;		// ampl ram reading
assign amp_wr_addr = (sp_out) ? wr_addr_dd : wr_addr;

always @(posedge clk) 
	sp_out_d <= sp_out;

always @(posedge clk)
	if (wr_en | wr_en_dd) begin			
		ampl_a_ram[amp_wr_addr] <= (sp_in) ? ker_a : ((sp_out_d) ? 0 : ampl_a_ram[amp_wr_addr]);				// ampl_a_ram update by spike in signal
		ampl_b_ram[amp_wr_addr] <= (sp_in) ? ker_b : ((sp_out_d) ? 0 : ampl_b_ram[amp_wr_addr]);		
	end

initial begin
  	for (int i=0; i<NEURON_NO; i++) begin						
		ampl_a_ram[i] = 0; 	
		ampl_b_ram[i] = 0;
	end
	rd_addr_d ='0;
	wr_addr = '0;
	wr_addr_d = '0;
	wr_addr_dd = '0;

	wr_en = '0;
	wr_en_d = '0;
	wr_en_dd = '0;
	sp_out_d = '0;
end
endmodule
