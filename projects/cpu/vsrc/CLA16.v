`include "defines.v"
module CLA16(
	input [15:0] x,
	input [15:0] y,
	input cin,
	output [15:0] f,
	output p_o,
	output g_o,
	output cout
);
	wire [4:0] c;
	wire [4:1] p, g;
	wire [2:0] useless_pin;
	CLA4 a1(x[3:0], y[3:0], cin, f[3:0], p[1], g[1], useless_pin[0]);
	CLA4 a2(x[7:4], y[7:4], c[1], f[7:4], p[2], g[2], useless_pin[1]);
	CLA4 a3(x[11:8], y[11:8], c[2], f[11:8], p[3], g[3], useless_pin[2]);
	CLA4 a4(x[15:12], y[15:12], c[3], f[15:12], p[4], g[4], cout);
	CLU clu(p, g, cin, c[4:1], p_o, g_o);
	
endmodule


