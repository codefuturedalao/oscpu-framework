`include "defines.v"
module CLU (
	input [4:1] p,
	input [4:1] g,
	input c0,
	
	output [4 : 1]c,
	output g_o,
	output p_o
);
	assign c[1] = g[1] | (p[1] & c0);
	assign c[2] = g[2] | (p[2] & g[1]) | (p[2] & p[1] & c0);
	assign c[3] = g[3] | (p[3] & g[2]) | (&{p[3:2], g[1]}) | (&{p[3:1], c0});
	assign c[4] = g[4] | (p[4] & g[3]) | (&{p[4:3], g[2]}) | (&{p[4:2], g[1]}) | (&{p[4:1], c0});
	assign g_o =  g[4] | (p[4] & g[3]) | (&{p[4:3], g[2]}) | (&{p[4:2], g[1]});
	assign p_o = &{p[4:1]};
	
endmodule

