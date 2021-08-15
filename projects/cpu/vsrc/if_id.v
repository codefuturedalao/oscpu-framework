`include "defines.v"

module if_id(
	input wire clk,
	input wire rst,
	input wire [1 : 0] stall,
	
	input wire [`INST_BUS] if_inst,
	input wire if_inst_valid,
	input wire [`REG_BUS] if_pc,

	output reg [`INST_BUS] id_inst,
	output reg id_inst_valid,
	output reg [`REG_BUS] id_pc
);
	
always
	@(posedge clk) begin
		if(rst == 1'b1) begin
			id_inst <= 32'b0;
			id_pc <= `ZERO_WORD;
		end
		else begin
			case(stall)
				`STALL_NEXT: begin
					id_inst <= if_inst;
					id_pc <= if_pc;
					id_inst_valid <= if_inst_valid;
				end
				`STALL_KEEP: begin
					id_inst <= id_inst;
					id_pc <= id_pc;
					id_inst_valid <= id_inst_valid;
				end
				`STALL_ZERO: begin
					id_inst <= 32'h0000_0000;
					//id_pc <= `ZERO_WORD;
					id_inst_valid <= 1'b0;
				end
				default: begin
					id_inst <= 32'h0000_0000;
					//id_pc <= `ZERO_WORD;
					id_inst_valid <= 1'b0;
				end
			endcase
		end
	end

endmodule
