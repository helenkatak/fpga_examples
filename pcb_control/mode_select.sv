`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2020/08/28 13:45:09
// Design Name: 
// Module Name: mode_select
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module mode_select
	(input logic clk,
	 input logic reset,
	 input logic en, 
	 input logic conn_mode, 	// FPGA or SMU connection modes
	 input logic op_mode		// SET, RESET or READ modes
    );
    
endmodule
