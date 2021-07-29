`include "defines.v"

module adder64(
	input wire [`REG_BUS] op1,
	input wire [`REG_BUS] op2,
	input wire cin,

	output wire [`REG_BUS] result,
	output wire overflow,
	output wire sign,
	output wire cout,
	output wire carry
);
	wire cout_63;
	cla_adder mycla_adder(op1, op2, cin, result, cout, cout_63);
	assign overflow = cout ^ cout_63;
	assign sign = result[63];
	assign carry = cout ^ cin;


endmodule
