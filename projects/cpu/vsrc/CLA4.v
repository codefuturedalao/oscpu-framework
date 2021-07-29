`include "defines.v"
module CLA4(
	input [3:0] x,
	input [3:0] y,
	input cin,
	output [3:0] f,
	output g_o,
	output p_o,
	output cout
);
	wire [4:1] c;
	wire [4:1] p, g;
	assign cout = c[3];
	FA_PG fa0(x[0], y[0], cin, f[0], p[1], g[1]);
	FA_PG fa1(x[1], y[1], c[1], f[1], p[2], g[2]);
	FA_PG fa2(x[2], y[2], c[2], f[2], p[3], g[3]);
	FA_PG fa3(x[3], y[3], c[3], f[3], p[4], g[4]);
	CLU clu(p, g, cin, c[4:1], g_o, p_o);

endmodule

