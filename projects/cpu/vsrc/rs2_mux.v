`include "defines.v"

module rs2_mux(
	input wire [`REG_BUS] ex_rs2_data,
	input wire [`REG_BUS] me_alu_result,
	input wire [`REG_BUS] wb_rd_data,
	input wire [1 : 0] rs2_src,

	output reg [`REG_BUS] new_rs2_data
);

always
	@(*) begin
		case(rs2_src)
			`RS2_EX: begin
				new_rs2_data = ex_rs2_data;
			end
			`RS2_ME: begin
				new_rs2_data = me_alu_result;
			end
			`RS2_WB: begin
				new_rs2_data = wb_rd_data;
			end
			default: begin
				new_rs2_data = `ZERO_WORD;
			end
		endcase
	end

endmodule
