`timescale 1ns / 1ps
module sm	
	(input logic clk1, clk2, reset, 
	 input logic rx_done,
	 input logic [7:0] rx_data_out,
	 output logic sft_clk, 			// shift clk: shifts a bit of shift register at positive edge
	 output logic sft_rst,			// shift register reset: resets all shift register values to low --> assign as reset
	 output logic latch_clk_d, 		// latch clk: output latch values to output values at positive edge 
	 output logic oe, 	 			// output enable: active low --> keep it low
	 output logic sr_sdi_c1c8, sr_sdi_c9c15, sr_sdi_c16c23, sr_sdi_c24c30,
	 output logic sr_sdi_r1r8, sr_sdi_r9r15, sr_sdi_r16r23, sr_sdi_r24r30);


logic rx_done;
logic [1:0] din_cnt;				// Flip between 1 and 2 (defualt =0) for reciving 8bit data from PC twice 
logic [4:0] row, col;				// Selected row and column number for state machine
logic rx_done_d;

always @(posedge clk1) rx_done_d <= rx_done;

always @(posedge clk1) 				 
	if (reset) din_cnt <= 0;			
	else if (rx_done) din_cnt <= (din_cnt == 2) ? 1 : din_cnt + 1;

always @(posedge clk1)
	if (reset) begin
		col <= 0;
		row <= 0;
	end
	else if (rx_done_d)
		if (din_cnt == 1) col <= rx_data_out[4:0];
		else if (din_cnt == 2) row <= rx_data_out[4:0];
	
logic [2:0] par_row_in;	// palleler input for PISO 
logic [2:0] par_col_in;	// pallaler input for PISO 
logic ser_row_out; 	 	// serial output of PISO
logic ser_col_out; 	 	// serial output of PISO
logic [2:0] piso_cnt;	// counter used in PISO modules
logic piso_en;			// PISO module enable signal

always @(posedge clk2)
	if (reset) sft_clk <= 0;
	else sft_clk <= ~sft_clk;

logic latch_clk, latch_clk_d;
always @(posedge clk2) latch_clk_d <= latch_clk;

piso piso_col_module(
	.clk(clk1), .reset(reset), .piso_en(piso_en),
	.par_in(par_col_in), .piso_cnt(piso_cnt),
	.ser_out(ser_col_out), .piso_end(piso_end_col));

piso piso_row_module(
	.clk(clk1), .reset(reset), .piso_en(piso_en),
	.par_in(par_row_in), .piso_cnt(piso_cnt),
	.ser_out(ser_row_out), .piso_end(piso_end_row));

typedef enum {IDLE, SFT_REG, LATCH_OUT, SFT_REG_RST, LATCH_OUT_RST} State;
State State_m;

always @(posedge clk1)
	if (reset) State_m  <= SFT_REG_RST;
	else begin
		case(State_m)
			IDLE: begin			
				piso_en 	<= 0;
				piso_cnt 	<= 0;				
				par_col_in 	<= 0;
				par_row_in 	<= 0;
				State_m 	<= (reset) ? SFT_REG_RST : ((rx_done_d & din_cnt==2) ? SFT_REG : State_m);
			end
			SFT_REG: begin
				piso_en     <= 1;
				piso_cnt    <= piso_cnt + 1;		
				par_col_in  <= (col<9) ? 8-(col%8) : ((col<24) ? 7-(col%8) : 6-(col%8));
				par_row_in  <= (row<9) ? 8-(row%8) : ((row<24) ? 7-(row%8) : 6-(row%8));
				State_m	   	<= (piso_cnt==7) ? LATCH_OUT : State_m;
			end
			LATCH_OUT: begin
				latch_clk	<= piso_end_row;
				piso_en 	<= (piso_end_row) ? 0 : piso_en;
				State_m 	<= (latch_clk) ? IDLE : State_m;
			end
			SFT_REG_RST: begin
				latch_clk 	<= 1;
				State_m	   	<= LATCH_OUT_RST;
			end
			LATCH_OUT_RST: begin
				latch_clk 	<= 0;
				State_m 	<= IDLE;				
			end
			default: begin
				State_m <= IDLE;
			end
		endcase
	end

always_comb begin
sft_rst = 1; 	// reset the shift register
oe 		= 1;

sr_sdi_c1c8   = 0;
sr_sdi_c9c15  = 0;
sr_sdi_c16c23 = 0;
sr_sdi_c24c30 = 0;
sr_sdi_r1r8   = 0;
sr_sdi_r9r15  = 0;
sr_sdi_r16r23 = 0;
sr_sdi_r24r30 = 0;

	case(State_m)
		IDLE : begin
			oe = 0;
			sft_rst = 1;

			sr_sdi_c1c8   = 0;
			sr_sdi_c9c15  = 0;
			sr_sdi_c16c23 = 0;
			sr_sdi_c24c30 = 0;
			sr_sdi_r1r8   = 0;
			sr_sdi_r9r15  = 0;
			sr_sdi_r16r23 = 0;
			sr_sdi_r24r30 = 0;
		end
		SFT_REG : begin
			oe = 0;

			if (col < 9) sr_sdi_c1c8 = ser_col_out;
			else if (col < 16) sr_sdi_c9c15 = ser_col_out;	
			else if (col < 24) sr_sdi_c16c23 = ser_col_out;
			else sr_sdi_c24c30 = ser_col_out;

			if (row < 9) sr_sdi_r1r8 = ser_row_out;
			else if (row < 16) sr_sdi_r9r15 = ser_row_out;	
			else if (row < 24) sr_sdi_r16r23 = ser_row_out;
			else sr_sdi_r24r30 = ser_row_out;

		end
		LATCH_OUT : begin
			oe = 0;


			if (col < 9) sr_sdi_c1c8 = ser_col_out;
			else if (col < 16) sr_sdi_c9c15 = ser_col_out;	
			else if (col < 24) sr_sdi_c16c23 = ser_col_out;
			else sr_sdi_c24c30 = ser_col_out;

			if (row < 9) sr_sdi_r1r8 = ser_row_out;
			else if (row < 16) sr_sdi_r9r15 = ser_row_out;	
			else if (row < 24) sr_sdi_r16r23 = ser_row_out;
			else sr_sdi_r24r30 = ser_row_out;
			
		end
		SFT_REG_RST : begin
			oe = 0;

			sr_sdi_c1c8   = 0;
			sr_sdi_c9c15  = 0;
			sr_sdi_c16c23 = 0;
			sr_sdi_c24c30 = 0;
			sr_sdi_r1r8   = 0;
			sr_sdi_r9r15  = 0;
			sr_sdi_r16r23 = 0;
			sr_sdi_r24r30 = 0;
		end
		LATCH_OUT_RST : begin
			oe = 0;
		end
	endcase
end

initial begin
	din_cnt   = 0;
	row 	  = 0;
	col 	  = 0;	
	rx_done_d = 0;
	piso_en   = 0;
	piso_cnt  = 0;
	par_col_in= 0;
	par_row_in= 0;
	State_m   = IDLE;
	sft_clk   = 0;
	latch_clk = 0;
	latch_clk_d = 0;
end
endmodule
