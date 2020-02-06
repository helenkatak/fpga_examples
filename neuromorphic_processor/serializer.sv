// Module for serializing data.
// NOTE: Input data width should be equal to a whole number times output data width (e.g. IN_W = 3*OUT_W)
`timescale 1ns / 1ps
module serializer #(IN_W=24, OUT_W=8)
	(input logic clk, reset,
	 input logic fifo_empty,
	 input logic tx_done,
	 input logic [IN_W-1:0] data_in,
	 output logic tx_dv,
	 output logic ser_rdy,
	 output logic [OUT_W-1:0] data_out);

localparam N_REG = IN_W/OUT_W;			// number of registers

genvar i;

logic [OUT_W-1:0] data_reg [N_REG-1:0];	// defining data registers
logic valid_reg [N_REG-1:0];			// validity register

struct {logic wr_tmp, wr_tmp_d, wr;
		logic next;
		logic [1:0] cnt;
		} ser;

struct {logic done_d, done_tmp, done;} tx;

// ser write signal
assign	ser.wr_tmp = (ser_rdy) ? 0 : (~data_out_val & ~fifo_empty);	// we should not be sending anything and something should be at fifo's output

always @(posedge clk) 
	ser.wr_tmp_d <= ser.wr_tmp;

assign ser.wr = ser.wr_tmp_d & ser.wr_tmp;

// ser next signal
always @(posedge clk) 
	tx.done_d <= tx_done;

assign tx.done_tmp = tx.done_d & tx_done;
assign tx.done = tx_done - tx.done_tmp;

always @(posedge clk) 
 	ser.next <= (ser_rdy) ? 0 : tx.done & data_out_val;	// when uart_tx is not busy and we have valid data at serializer's output, it will always be passed to the uart module at the next clock cycle

// ser ready signal
always @(posedge clk) begin
	if (reset) ser.cnt <= 0;
	else if (tx.done) ser.cnt <= (ser.cnt == 2) ? 0 : ser.cnt + 1;
end

assign ser_rdy = (ser.cnt == N_REG-1) & (tx.done);

always @(posedge clk)
	tx_dv <= ser.wr | ser.next;

generate
	for (i=0; i<N_REG; i++) begin: shift_reg
		always @(posedge clk)
			if (reset) valid_reg[i] <= 0;
			else if (ser.wr) valid_reg[i] <= 1;
			else if (ser.next | ser_rdy) valid_reg[i] <= (i==0) ? 0 : valid_reg[i-1];

		always @(posedge clk)
			if (reset) data_reg[i] <= 0;
			else if (ser.wr) data_reg[i] <= data_in[(i+1)*OUT_W-1:i*OUT_W];
			else if (ser.next | ser_rdy) data_reg[i] <= (i==0) ? 0 : data_reg[i-1];
	end
endgenerate

assign data_out = data_reg[N_REG-1];
assign data_out_val = valid_reg[N_REG-1];

initial begin
	for (int k=0; k<N_REG; k++) begin
		valid_reg[k] = 0;
		data_reg[k] = 0;
	end
	ser.cnt = '0;
	ser.wr_tmp_d = '0;
	ser.next = '0;
	tx_dv = '0;	
end
endmodule
