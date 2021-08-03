`include "defines.v"

module op2_mux(
	input wire [`REG_BUS] new_rs2_data,
	input wire [`REG_BUS] imm,
	input wire [1 : 0] alu_op2_src,

	output reg [`REG_BUS] op2
);

//combinational logic
always
	@(*) begin
		case(alu_op2_src)
			`OP2_REG: begin
				op2 = new_rs2_data;
			end
			`OP2_IMM: begin
				op2 = imm;
			end
			`OP2_4: begin
				op2 = 4;
			end
			default: begin
				op2 = `ZERO_WORD;
			end
		endcase
	end

endmodule

