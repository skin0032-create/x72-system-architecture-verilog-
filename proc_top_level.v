/*
Monash University ECE2072: Assignment 
This file contains the top level Verilog code to implement individual the CPU.

Please enter your student ID:
1. Shiho Kinebuchi (35467290)
2. Seong Ming Yin (34625291)
*/

module proc_top_level (
	input [8:0] SW,
	input [1:0] KEY,
	output [9:0] LEDR,
	output [6:0] HEX5 //to show tick
);

	wire [15:0] bus_output;
	wire [3:0] one_hot_tick;
	reg [3:0] state;
	
	//instantiate processor
	proc proc_1 (
		.en(1'b1),
		.clk(~KEY[1]),
		.rst(~KEY[0]),
		.din(SW[8:0]),
		.bus(bus_output),
		.tick_FSM_out(one_hot_tick)
	);
	
	//instantiate bcd to display tick
	BCD bcd_1 (
	.data(state), 
	.X(HEX5)
	);
	
	always @(*) begin
		case (one_hot_tick) //convert one-hot encoding to decimal for bcd
			4'b0001: state = 1;
			4'b0010: state = 2;
			4'b0100: state = 3;
			4'b1000: state = 4;
			default: state = 0;
		endcase
	end
	
	assign LEDR = bus_output[9:0];
	
endmodule
