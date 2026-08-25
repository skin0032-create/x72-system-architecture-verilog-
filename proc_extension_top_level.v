/*
Monash University ECE2072: Assignment 
This file contains the top level Verilog code to implement the extended version of CPU.

Please enter your student ID:
1. Shiho Kinebuchi (35467290)
2. Seong Ming Yin (34625291)
*/

module proc_extension_top_level (
	input [9:0] SW,
	input [1:0] KEY,
	output [9:0] LEDR,
	output [7:0] HEX0, HEX1, HEX2, HEX3, HEX4, //to display value in register H
	output [6:0] HEX5 //to show tick
);

	wire [15:0] bus_output;
	wire [3:0] one_hot_tick;
	reg [3:0] state;
	
	wire signed [15:0] proc_display; //contains value of register H in binary to be displayed
	wire signed [15:0] denom_1 = 16'd10000; //divisor (for lpm_divide use)
	wire signed [15:0] denom_2 = 16'd1000;
	wire signed [15:0] denom_3 = 16'd100;
	wire signed [15:0] denom_4 = 16'd10;
	wire signed [15:0] rem_1; //remainder (for lpm_divide use)
	wire signed [15:0] rem_2;
	wire signed [15:0] rem_3;
	wire signed [15:0] rem_4;
	wire signed [15:0] quo_1; //quotient (for lpm_divide use)
	wire signed [15:0] quo_2;
	wire signed [15:0] quo_3;
	wire signed [15:0] quo_4;
	
	assign LEDR = bus_output[9:0];
	
	//instantiate extended processor
	proc_extension proc_1 (
		.en(SW[9]),
		.clk(~KEY[1]),
		.rst(~KEY[0]),
		.din(SW[8:0]),
		.bus(bus_output),
		.tick_FSM_out(one_hot_tick),
		.display(proc_display)
	);

	//instantiate bcd to display tick
	BCD bcd_state_1(
		.data(state), 
		.X(HEX5)
	);
		
	//instantiate proc_divide built using lpm_divide IP block 
	proc_divide divide_1 (
		.denom(denom_1),
		.numer(proc_display),
		.quotient(quo_1), //first digit to be displayed on bcd
		.remain(rem_1) //get the remainder to repeat the process for second digit
	);
	
	proc_divide divide_2 (
		.denom(denom_2),
		.numer(rem_1),
		.quotient(quo_2), //second digit to be displayed on bcd
		.remain(rem_2) //get the remainder to repeat the process for third digit
	);
	
	proc_divide divide_3 (
		.denom(denom_3),
		.numer(rem_2),
		.quotient(quo_3), //third digit to be displayed on bcd
		.remain(rem_3) //get the remainder to repeat the process for fourth digit
	);
	
	proc_divide divide_4 (
		.denom(denom_4),
		.numer(rem_3),
		.quotient(quo_4), //fourth digit to be displayed on bcd
		.remain(rem_4) //fifth digit to be displayed on bcd
	);
	
	//instantiate bcd_decoder to display the number
	bcd_decoder bcd_disp_1(
		.number_data(proc_display), //original data in binary
		.digit_data(quo_1), //digit to be displayed on bcd
		.X(HEX4)
	);
	
	bcd_decoder bcd_disp_2(
		.number_data(proc_display), 
		.digit_data(quo_2),
		.X(HEX3)
	);
	
	bcd_decoder bcd_disp_3(
		.number_data(proc_display), 
		.digit_data(quo_3),
		.X(HEX2)
	);
	
	bcd_decoder bcd_disp_4(
		.number_data(proc_display), 
		.digit_data(quo_4),
		.X(HEX1)
	);
	
	bcd_decoder bcd_disp_5(
		.number_data(proc_display), 
		.digit_data(rem_4),
		.X(HEX0)
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

endmodule
