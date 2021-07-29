`include "defines.v"

module cla_adder(
	input wire [`REG_BUS] x,
	input wire [`REG_BUS] y,
	input cin,
	output wire [`REG_BUS] f,
	output wire cout,
	output wire cout_63
);
	
	wire [4:1] c;
	wire [4:1] p, g;
	wire p_o, g_o;
	assign cout = c[4];
	wire [2:0] useless_pin;
	CLA16 a1(x[15:0], y[15:0], cin, f[15:0], p[1], g[1], useless_pin[0]);
	CLA16 a2(x[31:16], y[31:16], c[1], f[31:16], p[2], g[2], useless_pin[1]);
	CLA16 a3(x[47:32], y[47:32], c[2], f[47:32], p[3], g[3], useless_pin[2]);
	CLA16 a4(x[63:48], y[63:48], c[3], f[63:48], p[4], g[4], cout_63);
	CLU clu(p, g, cin, c[4:1], g_o, p_o);
endmodule 
