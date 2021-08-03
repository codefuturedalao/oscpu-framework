`include "defines.v"

module op1_mux(
	input wire [`REG_BUS] new_rs1_data,
	input wire [`REG_BUS] pc,
	input wire alu_op1_src,
	
	output wire [`REG_BUS] op1
);	

//combinational logic
assign op1 = (alu_op1_src == `OP1_PC) ? pc : new_rs1_data;
	

endmodule
