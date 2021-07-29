`include "defines.v"
module FA_PG(
	input x,
	input y,
	input cin,
	
	output f,
	output p,
	output g
);

	assign f = x ^ y ^ cin;
	assign p = x | y;
	assign g = x & y;
	
endmodule
