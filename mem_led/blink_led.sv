`timescale 1ns / 1ps
module blink_led
    (input Logic clk, reset,
     output Logic led);

localparam CYC = 100000000;                //Clk cycle for blinking LED

count_end = CYC - 1;


always @(posedge clk, posedge reset)
        if(reset) count <= 0;
        else count <= count_end ? 0 : count + 1;
        
initial begin
	count = 0;
	led = 0;
end

endmodule
