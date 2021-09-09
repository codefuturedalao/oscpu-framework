`include "defines.v"
module pc_mux(
	input wire[`REG_BUS] old_pc,
	input wire control_transfer,
	input wire [`REG_BUS] control_target_pc,
	input wire exception_transfer,
	input wire [`REG_BUS] exception_target_pc,

	output reg[`REG_BUS] new_pc
);
	wire [`REG_BUS] result;
	assign result = old_pc + 4;
	//assign new_pc = exception_transfer ? exception_target_pc : (control_transfer == 1 ? control_target_pc : result);
	assign new_pc = exception_transfer ? exception_target_pc - 4 : (control_transfer == 1 ? control_target_pc - 4 : result);

endmodule
