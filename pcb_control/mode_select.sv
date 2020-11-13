`timescale 1ns / 1ps
module mode_select
	(input logic clk,
	 input logic reset,
	 input logic en, 
	 input logic conn_mode, 	// FPGA or SMU connection modes
	 input logic op_mode		// SET, RESET or READ modes
    );
    
endmodule
