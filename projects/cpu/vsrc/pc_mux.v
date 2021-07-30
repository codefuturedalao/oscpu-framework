`include "defines.v"
module pc_mux(
	input [`REG_BUS] old_pc,
	input branch,
	input b_flag,
	input [`REG_BUS] b_offset,
	output [`REG_BUS] new_pc
);
	/*TODO:
	i am not sure whether i should calculate new pc here, because i can use old_pc as op1 adn b_offset(or 4) as op2, then use rd_data as new_pc
	then i can save an adder, but i think that's too late for unconditional jump
	so i need to figure it out when i handle the pipeline micro-A
	*/
	wire [`REG_BUS] op;
	assign op = (branch & b_flag) == 1 ? b_offset : 4;
	assign new_pc = op + old_pc;

endmodule
