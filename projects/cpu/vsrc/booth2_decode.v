`include "defines.v"

module booth2_decode #(
	parameter WIDTH = 132
)
(
	input wire [2 : 0] booth2_code,
	input wire [WIDTH - 1 : 0] X,
	output wire cin,
	output wire [WIDTH - 1 : 0] Y
);

	assign Y = ({WIDTH{(booth2_code == 3'b000) | (booth2_code == 3'b111)}} & {WIDTH{1'b0}})
			|  ({WIDTH{(booth2_code == 3'b001) | (booth2_code == 3'b010)}} & X)
			|  ({WIDTH{(booth2_code == 3'b011)}} & X << 1)
			|  ({WIDTH{(booth2_code == 3'b100)}} & ~(X << 1))
			|  ({WIDTH{(booth2_code == 3'b101) | (booth2_code == 3'b110)}} & ~X);

	assign cin = booth2_code[2] & ~(&booth2_code);


endmodule
