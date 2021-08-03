`include "defines.v"

module ex_me(
	input wire clk,
	input wire rst,
	input wire stall,
	/* for branch and jump */	
	input wire [`REG_BUS] ex_target_pc,
	input wire ex_branch,
	input wire ex_jump,
	input wire ex_b_flag,
	/* for access mem */
	input wire ex_mem_rena,
	input wire ex_mem_wena,
	input wire ex_mem_ext_un,
	input wire ex_mem_to_reg,
	input wire [7 : 0] ex_mem_byte_enable, 
	input wire [`REG_BUS] ex_alu_result,
	input wire [`REG_BUS] ex_new_rs2_data,
	/* for wb write register */	
	input wire ex_rd_wena,
	input wire [4 : 0] ex_rd_waddr,
	input wire [`REG_BUS] ex_pc,			//for difftest
	input wire [`INST_BUS] ex_inst,

	output reg [`REG_BUS] me_target_pc,
	output reg me_branch,
	output reg me_jump,
	output reg me_b_flag,

	output reg me_mem_rena,
	output reg me_mem_wena,
	output reg me_mem_ext_un,
	output reg me_mem_to_reg,
	output reg [7 : 0] me_mem_byte_enable, 
	output reg [`REG_BUS] me_alu_result,
	output reg [`REG_BUS] me_new_rs2_data,

	output reg me_rd_wena,
	output reg [4 : 0] me_rd_waddr,
	output reg [`REG_BUS] me_pc,
	output reg [`INST_BUS] me_inst
);

always
	@(posedge clk) begin
		if(clk == 1'b1) begin
			me_target_pc <= `ZERO_WORD;
			me_branch <= 1'b0;
			me_jump <= 1'b0;
			me_b_flag <= 1'b0;
			
			me_mem_rena <= 1'b0;
			me_mem_wena <= 1'b0;
			me_mem_ext_un <= 1'b0;
			me_mem_to_reg <= 1'b0;

			me_mem_byte_enable <= 8'b0;
			me_alu_result <= `ZERO_WORD;
			me_new_rs2_data <= `ZERO_WORD;

			me_rd_wena <= 1'b0;
			me_rd_waddr <= 5'b00000;	
			me_pc <= `ZERO_WORD;	
			me_inst <= 32'h0000_000;
		end
		else begin
			case(stall)
				`STALL_NEXT: begin
					me_target_pc <= ex_target_pc;
					me_branch <= ex_branch;
					me_jump <= ex_jump;
					me_b_flag <= ex_b_flag;
					
					me_mem_rena <= ex_mem_rena;
					me_mem_wena <= ex_mem_wena;
					me_mem_ext_un <= ex_mem_ext_un;
					me_mem_to_reg <= ex_mem_to_reg;

					me_mem_byte_enable <= ex_mem_byte_enable;
					me_alu_result <= ex_alu_result;
					me_new_rs2_data <= ex_new_rs2_data;

					me_rd_wena <= ex_rd_wena;
					me_rd_waddr <= ex_rd_waddr;
					me_pc <= ex_pc;	
					me_inst <= ex_inst;
				end
				`STALL_KEEP: begin
				end
				`STALL_ZERO: begin
					me_target_pc <= `ZERO_WORD;
					me_branch <= 1'b0;
					me_jump <= 1'b0;
					me_b_flag <= 1'b0;
					
					me_mem_rena <= 1'b0;
					me_mem_wena <= 1'b0;
					me_mem_ext_un <= 1'b0;
					me_mem_to_reg <= 1'b0;

					me_mem_byte_enable <= 8'b0;
					me_alu_result <= `ZERO_WORD;
					me_new_rs2_data <= `ZERO_WORD;

					me_rd_wena <= 1'b0;
					me_rd_waddr <= 5'b00000;	
					me_pc <= `ZERO_WORD;
					me_inst <= 32'h0000_000;
				end
				default: begin
					me_target_pc <= `ZERO_WORD;
					me_branch <= 1'b0;
					me_jump <= 1'b0;
					me_b_flag <= 1'b0;
					
					me_mem_rena <= 1'b0;
					me_mem_wena <= 1'b0;
					me_mem_ext_un <= 1'b0;
					me_mem_to_reg <= 1'b0;

					me_mem_byte_enable <= 8'b0;
					me_alu_result <= `ZERO_WORD;
					me_new_rs2_data <= `ZERO_WORD;

					me_rd_wena <= 1'b0;
					me_rd_waddr <= 5'b00000;	
					me_pc <= `ZERO_WORD;
					me_inst <= 32'h0000_000;
				end
			endcase
		end	
	end

endmodule
