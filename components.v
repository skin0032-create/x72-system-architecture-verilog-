/*
Monash University ECE2072: Assignment 
This file contains Verilog code to implement individual components to be used in the CPU.

Please enter your name and student ID:
1. Shiho Kinebuchi (35467290)
2. Seong Ming Yin (34625291)
*/

//COMPONENTS FOR TASK 1
module sign_extend (in, ext);
	/* 
	 * This module sign extends the 9-bit Din to a 16-bit output.
	 */
	input [8:0] in;
   output reg [15:0] ext;
	
	always @(*) begin
		ext[8:0] = in; //remain lower bits
		if (in[8]==0) ext[15:9] = 7'b0000000; //extend according to sign
		else ext[15:9] = 7'b1111111;
	end
endmodule


module tick_FSM(rst, clk, enable, tick);
	/* 
	 * This module implements a tick FSM that will be used to
	 * control the actions of the control unit
	 */
	input rst;
	input clk;
	input enable;
	output reg [3:0] tick;
	parameter tick_1 = 4'b0001, tick_2 = 4'b0010, tick_3 = 4'b0100, tick_4 = 4'b1000;

	always @(posedge clk) begin
		if(rst) begin
			tick <= tick_1; //resets to first state
		end 
		
		else if (enable) begin
			case(tick) //proceed to next state when processor is enabled
				tick_1:
					tick <= tick_2;
				tick_2: 
					tick <= tick_3;
				tick_3:
					tick <= tick_4;
				tick_4: 
					tick <= tick_1;	
				default: 
					tick <= tick_1; 
			endcase
		end
	end
endmodule


module multiplexer (SignExtDin, R0, R1, R2, R3, R4, R5, R6, R7, G, sel, Bus);
	/* 
	* This module takes 10 inputs and places the correct input onto the bus.
	*/
	input [15:0] SignExtDin, R0, R1, R2, R3, R4, R5, R6, R7, G;
	input [3:0] sel;
	output reg [15:0] Bus;  
	
	always @(*) begin
		 case (sel) //select which input to be placed on bus according to selector
			  4'd0: Bus = SignExtDin; 
			  4'd1: Bus = R0;
			  4'd2: Bus = R1;
			  4'd3: Bus = R2;
			  4'd4: Bus = R3;
			  4'd5: Bus = R4;
			  4'd6: Bus = R5;
			  4'd7: Bus = R6;
			  4'd8: Bus = R7;
			  4'd9: Bus = G;
			  default: Bus = 16'b0;
		endcase
	end
endmodule 


module ALU (input_a, input_b, alu_op, result);
	/* 
	 * This module implements the arithmetic logic unit of the processor.
	 */
	input signed [15:0] input_a;
	input signed [15:0] input_b;
	input [2:0] alu_op;
	output reg signed [15:0] result;
	
	always @(*) begin 
		case (alu_op)
			3'b000: result = input_a * input_b;
			3'b001: result = input_a + input_b;
			3'b010: result = input_a - input_b;
			3'b011: 
				begin
					if (input_a > 0) result = input_b << input_a; 
					else result = input_b >> -input_a; //convert input a to positive since >> only considers magnitude
				end	
			default: result = 16'bx; 
		endcase
	end
endmodule


module register_n(data_in, r_in, clk, Q, rst);
	// To set parameter N during instantiation, you can use:
	// register_n #(.N(num_bits)) reg_IR(.....), 
	// where num_bits is how many bits you want to set N to
	// and "..." is your usual input/output signals

	/* 
	 * This module implements registers that will be used in the processor.
	 */
	parameter N = 16; 
	input signed [N-1:0] data_in;
	input r_in;
	input clk;
	input rst;
	output reg signed [N-1:0] Q;
	
	always @(posedge clk) begin
		if (rst) Q <= {N{1'b0}};  
		else if (r_in) Q <= data_in; //stores data when register is enabled
	end
endmodule


//COMPONENTS FOR TASK 2 
module BCD(data, X);
	/* 
	* This module takes in data from 1-9 to and control the seven segments of X to display the number
	*/
   input [3:0] data;
   output reg [6:0] X;
	
	always @(*) begin
		case (data)
			4'b0000: X = 7'b1000000; //sequence is g-a, 1 means off, 0 means on
			4'b0001: X = 7'b1111001; 
			4'b0010: X = 7'b0100100;
			4'b0011: X = 7'b0110000;
			4'b0100: X = 7'b0011001;
			4'b0101: X = 7'b0010010;
			4'b0110: X = 7'b0000010;
			4'b0111: X = 7'b1111000;
			4'b1000: X = 7'b0000000;
			4'b1001: X = 7'b0010000; 
			default: X = 7'b1111111;
		endcase
	end
endmodule


//COMPONENTS FOR TASK 3
module bcd_decoder(number_data, digit_data, X);
	/* 
	* This module takes in data from 1-9 to and control the eight segments of X to display the number (including decimal point)
	*/
	input signed [15:0] number_data;
	input signed [15:0] digit_data;
	output reg [7:0] X;
	
	always @(*) begin
		if (number_data[15] == 0) X[7] = 1; //use the most significant bit to determine whether original data is negative then turn on/off decimal point
		else X[7] = 0;
		
		case (digit_data)
			16'd0: X[6:0] = 7'b1000000; 
			-16'd1, 16'd1: X[6:0] = 7'b1111001; //sequence is g-a, 1 means off, 0 means on
			-16'd2, 16'd2: X[6:0] = 7'b0100100;
			-16'd3, 16'd3: X[6:0] = 7'b0110000;
			-16'd4, 16'd4: X[6:0] = 7'b0011001;
			-16'd5, 16'd5: X[6:0] = 7'b0010010;
			-16'd6, 16'd6: X[6:0] = 7'b0000010;
			-16'd7, 16'd7: X[6:0] = 7'b1111000;
			-16'd8, 16'd8: X[6:0] = 7'b0000000;
			-16'd9, 16'd9: X[6:0] = 7'b0010000;
			default: X[6:0] = 7'b1111111;
		endcase
	end
endmodule


//COMPONENTS FOR TASK 4
module register_PC (enable_next, clk, rst, enable_immi, immi, Q);
	/* 
	* This module is a special purpose register for PC
	*/
	input enable_immi;
	input enable_next;
	input clk;
	input rst;
	input signed [15:0] immi;
	output reg signed [15:0] Q;
	
	always @(posedge clk) begin
		if (rst) begin
			Q <= 0;
		end else if (enable_next) begin
			Q <= Q + 16'd1; //to get next address
		end else if (enable_immi) begin
			Q <= Q + immi + immi + 16'd1; //for jump instruction
		end
	end 
endmodule

module ALU_extended (input_a, input_b, alu_op, result, Rx_flag);
	/* 
	 * This module implements the arithmetic logic unit of the processor.
	 */
	input signed [15:0] input_a;
	input signed [15:0] input_b;
	input [2:0] alu_op;
	output reg signed [15:0] result;
	output reg Rx_flag; //for task 4 only
	
	always @(*) begin 
		case (alu_op)
			3'b000: result = input_a * input_b;
			3'b001: result = input_a + input_b;
			3'b010: result = input_a - input_b;
			3'b011: 
				begin
					if (input_a > 0) result = input_b << input_a; 
					else result = input_b >> -input_a; //convert input a to positive since >> only considers magnitude
				end
			3'b100: 
				begin
					if (input_b == 0) Rx_flag = 1; //determine whether Rx is 0 
					else Rx_flag = 0;
				end	
			default: result = 16'bx; 
		endcase
	end
endmodule

