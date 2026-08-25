/*
Monash University ECE2072: Assignment 
This file contains Verilog code to implement the extended version of CPU with ROM.

Please enter your student ID:
1. Shiho Kinebuchi (35467290)
2. Seong Ming Yin (34625291)
*/

module proc_memory(en, clk, rst, din, bus, R0, R1, R2, R3, R4, R5, R6, R7, tick_FSM_out, display, PC_out);
	//declare inputs and outputs
	input en;
	input clk;
	input rst;
	input [8:0] din; //instruction or immediate value
	output [15:0] bus;
	output [15:0] R0, R1, R2, R3, R4, R5, R6, R7; //internal register values (for testbenching purposes only)
	output [3:0] tick_FSM_out; //tick
	output [15:0] display; //contains value of register to be displayed
	output [15:0] PC_out; //contains address to be given to ROM 
	
   //declare wires and regs
	reg r_in_R0, r_in_R1, r_in_R2, r_in_R3, r_in_R4, r_in_R5, r_in_R6, r_in_R7, r_in_IR, r_in_A, r_in_G, r_in_H; //to control enable of each register
	reg [2:0] alu_operand; //to select an operation in ALU
	reg [3:0] bus_control; //to select an input to be placed on the bus
	wire [8:0] IR_out;
	wire [15:0] A_out, G_out;
	wire [15:0] sign_ext_out;
	wire [15:0] alu_out;
	wire alu_flag; //flag to indicate whether Rx is 0
	reg add_immi; //enable for taking in immediate
	reg next_addr; //enable for proceeding to next address
	
	//instantiate special purpose PC register
	register_PC proc_reg_PC(.enable_next(next_addr), .clk(clk), .rst(rst), .enable_immi(add_immi), .immi(sign_ext_out), .Q(PC_out));
	
	//instantiate registers
	register_n #(.N(16)) proc_reg_R0(.data_in(bus), .r_in(r_in_R0), .rst(rst), .clk(clk), .Q(R0));
	register_n #(.N(16)) proc_reg_R1(.data_in(bus), .r_in(r_in_R1), .rst(rst), .clk(clk), .Q(R1));
	register_n #(.N(16)) proc_reg_R2(.data_in(bus), .r_in(r_in_R2), .rst(rst), .clk(clk), .Q(R2));
	register_n #(.N(16)) proc_reg_R3(.data_in(bus), .r_in(r_in_R3), .rst(rst), .clk(clk), .Q(R3));
	register_n #(.N(16)) proc_reg_R4(.data_in(bus), .r_in(r_in_R4), .rst(rst), .clk(clk), .Q(R4));
	register_n #(.N(16)) proc_reg_R5(.data_in(bus), .r_in(r_in_R5), .rst(rst), .clk(clk), .Q(R5));
	register_n #(.N(16)) proc_reg_R6(.data_in(bus), .r_in(r_in_R6), .rst(rst), .clk(clk), .Q(R6));
	register_n #(.N(16)) proc_reg_R7(.data_in(bus), .r_in(r_in_R7), .rst(rst), .clk(clk), .Q(R7));
	
	register_n #(.N(9)) proc_reg_IR(.data_in(din), .r_in(r_in_IR), .rst(rst), .clk(clk), .Q(IR_out));
	register_n #(.N(16)) proc_reg_A(.data_in(bus), .r_in(r_in_A), .rst(rst), .clk(clk), .Q(A_out));
	register_n #(.N(16)) proc_reg_G(.data_in(alu_out), .r_in(r_in_G), .rst(rst), .clk(clk), .Q(G_out));
	register_n #(.N(16)) proc_reg_H(.data_in(bus), .r_in(r_in_H), .rst(rst), .clk(clk), .Q(display)); // register H to store value for display
	 
	//instantiate multiplexer
	multiplexer proc_mux(.SignExtDin(sign_ext_out), .R0(R0), .R1(R1), .R2(R2), .R3(R3), .R4(R4), .R5(R5), .R6(R6), .R7(R7), .G(G_out), .sel(bus_control), .Bus(bus));
    
   //instantiate ALU
	ALU_extended proc_alu(.input_a(A_out), .input_b(bus), .alu_op(alu_operand), .result(alu_out), .Rx_flag(alu_flag));
    
   //instantiate tick counter
	tick_FSM proc_tick_FSM (.rst(rst), .enable(en), .clk(~clk), .tick(tick_FSM_out));
	
	//instantiate sign extender
	sign_extend proc_sign_ext (.in(din), .ext(sign_ext_out));
    
   //define control unit
   always @(*) begin 
		//turn off all control signals at the start
		add_immi = 0; //for PC register
		next_addr = 0; //for PC register
		r_in_R0 = 0;
		r_in_R1 = 0;
		r_in_R2 = 0;
		r_in_R3 = 0;
		r_in_R4 = 0;
		r_in_R5 = 0;
		r_in_R6 = 0;
		r_in_R7 = 0; 
		r_in_IR = 0;
		r_in_A = 0;
		r_in_G = 0; 
		r_in_H = 0;
		alu_operand = 3'b111; //not select any operand
		bus_control = 4'd15; //not select any input
		  
		//turn on specific control signals based on current tick
      case (tick_FSM_out)
         4'b0001: 
            begin
					r_in_IR = 1'b1; //enable instruction register to store instruction	
					next_addr = 1'b1; //enable PC register to add 1 to current address to get new address			
            end
            
         4'b0010: 
            begin
					case(IR_out[8:6]) //determine opcode
						3'b001, 3'b011, 3'b100: //add, sub, mul
							begin
								if (IR_out[5:3] == 3'b111) bus_control = {{1{1'b1}},(IR_out[5:3]+3'b001)}; 
								else bus_control = {{1{1'b0}},(IR_out[5:3]+3'b001)}; //select Rx to be placed on bus
								r_in_A = 1'b1; //store value of Rx in A 
							end
						3'b010, 3'b101: //addi, ssi
							begin
								bus_control = 4'd0; //select sign extender
								r_in_A = 1'b1;
							end
						3'b111: //movi
							begin
								bus_control = 4'd0; 
								if (IR_out[5:3] == 3'b000) r_in_R0 = 1'b1; //determine which Rx to enable for storing value
								else if (IR_out[5:3] == 3'b001) r_in_R1 = 1'b1;
								else if (IR_out[5:3] == 3'b010) r_in_R2 = 1'b1;
								else if (IR_out[5:3] == 3'b011) r_in_R3 = 1'b1;
								else if (IR_out[5:3] == 3'b100) r_in_R4 = 1'b1;
								else if (IR_out[5:3] == 3'b101) r_in_R5 = 1'b1;
								else if (IR_out[5:3] == 3'b110) r_in_R6 = 1'b1;
								else r_in_R7 = 1'b1;	
							end
						3'b000: //disp
							begin
								if (IR_out[5:3] == 3'b111) bus_control = {{1{1'b1}}, (IR_out[5:3] + 3'b001)};
								else bus_control = {{1{1'b0}}, (IR_out[5:3] + 3'b001)};
								r_in_H = 1'b1; //store value of Rx in H
							end
						3'b110: //bez
							begin
								if (IR_out[5:3] == 3'b111) bus_control = {{1{1'b1}}, (IR_out[5:3] + 3'b001)};
								else bus_control = {{1{1'b0}}, (IR_out[5:3] + 3'b001)};
								alu_operand = 3'b100; //determine whether Rx is 0
								if (alu_flag == 1) add_immi = 1'b1; //if Rx is 0, enable the PC register to perform operation with immediate to get new address
								else next_addr = 1'b1; //if Rx is not 0, enable PC register to add 1 to current address to get new address	
							end
						default:
							begin
								r_in_R0 = 0;
								r_in_R1 = 0;
								r_in_R2 = 0;
								r_in_R3 = 0;
								r_in_R4 = 0;
								r_in_R5 = 0;
								r_in_R6 = 0;
								r_in_R7 = 0;
								r_in_IR = 0;
								r_in_A = 0;
								r_in_G = 0;
								alu_operand = 3'b111;
								bus_control = 4'd15;
							end
					endcase
            end
            
			4'b0100: 
				begin
					case(IR_out[8:6])
						3'b001: //add
							begin
								if (IR_out[2:0] == 3'b111) bus_control = {{1{1'b1}},(IR_out[2:0]+3'b001)}; //select Ry to be placed on bus
								else bus_control = {{1{1'b0}},(IR_out[2:0]+3'b001)}; 
								alu_operand = 3'b001; //select an alu operation
								r_in_G = 1'b1; //store result in register G
							end
						3'b010: //addi
							begin
								if (IR_out[5:3] == 3'b111) bus_control = {{1{1'b1}},(IR_out[5:3]+3'b001)};
								else bus_control = {{1{1'b0}},(IR_out[5:3]+3'b001)}; 
								alu_operand = 3'b001;
								r_in_G = 1'b1;
							end
						3'b011: //sub
							begin
								if (IR_out[2:0] == 3'b111) bus_control = {{1{1'b1}},(IR_out[2:0]+3'b001)};
								else bus_control = {{1{1'b0}},(IR_out[2:0]+3'b001)};
								alu_operand = 3'b010; 
								r_in_G = 1'b1;
							end
							
						3'b100: //mul
							begin
								if (IR_out[2:0] == 3'b111) bus_control = {{1{1'b1}},(IR_out[2:0]+3'b001)};
								else bus_control = {{1{1'b0}},(IR_out[2:0]+3'b001)};
								alu_operand = 3'b000; 
								r_in_G = 1'b1;
							end
								
						3'b101: //ssi
							begin
								if (IR_out[5:3] == 3'b111) bus_control = {{1{1'b1}},(IR_out[5:3]+3'b001)};
								else bus_control = {{1{1'b0}},(IR_out[5:3]+3'b001)}; 
								alu_operand = 3'b011;
								r_in_G = 1'b1;
							end
						default:
							begin
								r_in_R0 = 0;
								r_in_R1 = 0;
								r_in_R2 = 0;
								r_in_R3 = 0;
								r_in_R4 = 0;
								r_in_R5 = 0;
								r_in_R6 = 0;
								r_in_R7 = 0;
								r_in_IR = 0;
								r_in_A = 0;
								r_in_G = 0;
								alu_operand = 3'b111;
								bus_control = 4'd15;
							end
					endcase
				end
            
         4'b1000:
				begin
					case(IR_out[8:6])
						3'b001, 3'b010, 3'b011, 3'b100, 3'b101: //add, addi, sub, mul, ssi
							begin
								bus_control = 4'd9; //select register G
								if (IR_out[5:3] == 3'b000) r_in_R0 = 1'b1; //determine which Rx to enable for storing value
								else if (IR_out[5:3] == 3'b001) r_in_R1 = 1'b1;
								else if (IR_out[5:3] == 3'b010) r_in_R2 = 1'b1;
								else if (IR_out[5:3] == 3'b011) r_in_R3 = 1'b1;
								else if (IR_out[5:3] == 3'b100) r_in_R4 = 1'b1;
								else if (IR_out[5:3] == 3'b101) r_in_R5 = 1'b1;
								else if (IR_out[5:3] == 3'b110) r_in_R6 = 1'b1;
								else r_in_R7 = 1'b1;	
							end
						default:
							begin
								r_in_R0 = 0;
								r_in_R1 = 0;
								r_in_R2 = 0;
								r_in_R3 = 0;
								r_in_R4 = 0;
								r_in_R5 = 0;
								r_in_R6 = 0;
								r_in_R7 = 0;
								r_in_IR = 0;
								r_in_A = 0;
								r_in_G = 0;
								alu_operand = 3'b111;
								bus_control = 4'd15;
							end
					endcase
					if (IR_out[8:6] != 3'b110) next_addr = 1'b1; //if the instruction opcode is not jump, then enable PC to add 1 to current address
				end
            
         default:
				begin
					r_in_R0 = 0;
					r_in_R1 = 0;
					r_in_R2 = 0;
					r_in_R3 = 0;
					r_in_R4 = 0;
					r_in_R5 = 0;
					r_in_R6 = 0;
					r_in_R7 = 0;
					r_in_IR = 0;
					r_in_A = 0;
					r_in_G = 0;
					alu_operand = 3'b111;
					bus_control = 4'd15;
				end
      endcase
   end

endmodule


