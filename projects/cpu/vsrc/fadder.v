`include "defines.v"

module fadder(
	input wire x,
	input wire y,
	input wire cin,
	
	output wire s,
	output wire c
);

	assign s = x ^ y ^ cin;
	assign c = x & y | x & cin | y & cin;
	
endmodule
