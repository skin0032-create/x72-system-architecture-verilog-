# x72-system-architecture-verilog-

The x72 processor is a simple processor that consists of several individual components that work together to perform different operations over a four tick cycle depending on the instructions loaded into the instruction register. The aim of this project is to design and implement a functional x72 processor in the DE-10 FPGA board. 

These are the components implemented in the architecture.

ALU :- 
The ALU performs all basic arithmetic operations based on the operation code. It has two signed 16-bit inputs for numbers a and b, a 3-bit input for operation code and a 16-bit output for result.

The ALU's combinational logic is implemented using a case statement based on the 3-bit alu op-code to select the corresponding arithmetic or shift operation. The logical shifting is executed by using if-statement because the operator >> does not consider the sign of shift on its own. If input_a is positive, input_b shifts to the right by the magnitude of input_a. If input_a is negative, input_b shifts to the left by the magnitude of input_a. The default case handles all unspecified opcodes by setting the 16-bit result to the unknown value correctly modeling a "don't care" state. 

Register :- 
The register is used to store the instructions or data that the processor needs to access. It has four inputs (a n-bit data input, an enable, a clock and a reset) and one n-bit stored value output.  On the rising edge of the clock, the data is stored if enable (r_in) is high. If enable (r_in) is low, the register holds the previous value and acts as a storage element. If the reset (rst) is high, the register is reset to 0. In our module, we implemented a parameterised register using a parameter N which represents the number of bits the user wants to implement. This allows the user to reuse the same module for different numbers of bits. In our processor, the instruction register stores 9-bits since instruction is 9 bits input while other registers store 16-bits. 

Sign Extender :-
This is used to correctly convert the value of smaller bit width to match the 16 bit width used by the bus while preserving the sign and the value. The module accepts 9-bits input and extends to 16-bits output by replicating the most significant bit or the sign bit to ensure correct representation in two’s complement form.

Tick Counter :-
The tick counter is a finite state machine that controls 4 states of the processor (4 ticks encoded using one-hot encoding). The tick counter has three inputs (reset, enable and clock) and a 4-bit tick output. The module uses a case statement based on the current state. When the enable is high, the counter moves to the next state on the rising edge of the clk (clock). When rst (reset) is high, the counter resets to the first state, tick1. The module is designed to wrap around after tick4, returning to tick1. The state of the ticks are  parameterized for easier understanding. 

Multiplexer :-
The multiplexer selectively routes the bus to different registers controlled by the selector to ensure the correct data can be put on the bus and moved along the datapath. The module has ten 16-bits inputs (Register R0-R7, sign-extender and register G), a 3-bit selector input and a 16-bit bus output . By using a case statement based on the selector (sel), the multiplexer determines which input source is to be placed onto the bus. If the sel does not match with any of the cases, the bus defaults to 0. 
