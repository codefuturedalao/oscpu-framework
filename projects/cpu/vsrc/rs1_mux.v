`include "defines.v"

module rs1_mux(
	input wire [`REG_BUS] ex_rs1_data,
	input wire [`REG_BUS] me_alu_result,
	input wire [`REG_BUS] wb_rd_data,
	input wire [1 : 0] rs1_src,

	output reg [`REG_BUS] new_rs1_data
);

always
	@(*) begin
		case(rs1_src)
			`RS1_EX: begin
				new_rs1_data = ex_rs1_data;
			end
			`RS1_ME: begin
				new_rs1_data = me_alu_result;
			end
			`RS1_WB: begin
				new_rs1_data = wb_rd_data;
			end
			default: begin
				new_rs1_data = `ZERO_WORD;
			end
		endcase
	end

endmodule
