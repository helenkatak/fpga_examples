`timescale 1ns / 1ps
module amplitude #(parameter NEURON_NO=2**8, AMPL_WID=12, TS_WID=12) 
	(input logic clk, reset,
	 input logic sp_in, sp_out,
	 input logic [AMPL_WID-1:0] ker_a, ker_b,
	 input logic [TS_WID-1:0] weight_const,
	 input logic re,
	 input logic [$clog2(NEURON_NO)-1:0] rd_addr,
	 input logic [$clog2(NEURON_NO)-1:0] wr_addr,
	 output logic [AMPL_WID-1:0] ampl_a, ampl_b);

(*ram_style = "distributed"*)  logic [AMPL_WID-1:0] ampl_a_ram [NEURON_NO-1:0];	// amplitude A ram
(*ram_style = "distributed"*)  logic [AMPL_WID-1:0] ampl_b_ram [NEURON_NO-1:0];	// amplitude B ram

always @(posedge clk) 								// ampl reading
	if (reset) begin 
		ampl_a <= 0;
		ampl_b <= 0;
	end
	else if (re) begin
		ampl_a <= ampl_a_ram[rd_addr];
		ampl_b <= ampl_b_ram[rd_addr]; 
	end
	else begin
		ampl_a <= 0;
		ampl_b <= 0;
	end

always @(posedge clk) 								// ampl writing
	if (sp_out) begin								
		ampl_a_ram[wr_addr] <= 0;
		ampl_b_ram[wr_addr] <= 0;
	end
	else if (sp_in) begin
		ampl_a_ram[wr_addr] <= weight_const+ker_a;		
		ampl_b_ram[wr_addr] <= weight_const+ker_b;
	end

initial begin
	ampl_a = '0;
	ampl_b = '0;
  	for (int i=0; i<NEURON_NO; i++) begin						
		ampl_a_ram[i] = 0; 	
		ampl_b_ram[i] = 0;
	end
end
endmodule
