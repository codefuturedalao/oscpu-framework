`include "defines.v"
module pc_mux(
	input wire[`REG_BUS] old_pc,
	input wire branch,
	input wire jump,
	input wire b_flag,
	input wire target_pc,

	output wire transfer,
	output reg[`REG_BUS] new_pc
);
	wire [`REG_BUS] result;
	assign result = old_pc + 4;
	assign transfer = (b_flag & branch) | jump;
	assign new_pc = transfer == 1 ? target_pc : result;

endmodule
