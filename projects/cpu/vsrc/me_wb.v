`include "defines.v"

module me_wb(
	input wire clk,
	input wire rst,
	input wire [1 : 0] stall,
	
	input wire [`REG_BUS] me_alu_result,	
	input wire [`REG_BUS] me_mem_data,
	input wire me_mem_to_reg,
	input wire me_mem_ext_un,
	input wire [7 : 0] me_mem_byte_enable,
	input wire me_rd_wena,
	input wire [4 : 0] me_rd_waddr,
	input wire [`REG_BUS] me_pc,			//for difftest
	input wire [`INST_BUS] me_inst,
	input wire me_inst_valid,
	input wire me_csr_rena,
	input wire me_csr_wena,
	input wire [1 : 0] me_csr_op,
	input wire [`REG_BUS] me_new_rs1_data,

	output reg [`REG_BUS] wb_alu_result,	
	output reg [`REG_BUS] wb_mem_data,
	output reg wb_mem_to_reg,
	output reg wb_mem_ext_un,
	output reg [7 : 0] wb_mem_byte_enable,
	output reg wb_rd_wena,
	output reg [4 : 0] wb_rd_waddr,
	output reg [`REG_BUS] wb_pc,
	output reg [`INST_BUS] wb_inst,
	output reg wb_inst_valid,
	output reg wb_csr_rena,
	output reg wb_csr_wena,
	output reg [1 : 0] wb_csr_op,
	output reg [`REG_BUS] wb_new_rs1_data
);

always
	@(posedge clk) begin
		if(rst == 1'b1) begin
			wb_alu_result <= `ZERO_WORD;
			wb_mem_data <= `ZERO_WORD;
			wb_mem_to_reg <= 1'b0;
			wb_mem_ext_un <= 1'b0;
			wb_mem_byte_enable <= 8'b0000_0000;
			wb_rd_wena <= 1'b0;
			wb_rd_waddr <= 5'b00000;
			wb_pc <= `ZERO_WORD;
			wb_inst <= 32'h0000_0000;
			wb_inst_valid <= 1'b0;
			wb_csr_rena <= 1'b0;
			wb_csr_wena <= 1'b0;
			wb_csr_op <= 2'b00;
			wb_new_rs1_data <= `ZERO_WORD;
		end
		else begin
			case(stall)
				`STALL_NEXT: begin
					wb_alu_result <= me_alu_result;
					wb_mem_data <= me_mem_data;
					wb_mem_to_reg <= me_mem_to_reg;
					wb_mem_ext_un <= me_mem_ext_un;
					wb_mem_byte_enable <= me_mem_byte_enable;
					wb_rd_wena <= me_rd_wena;
					wb_rd_waddr <= me_rd_waddr;
					wb_pc <= me_pc;
					wb_inst <= me_inst;
					wb_inst_valid <= me_inst_valid;
					wb_csr_rena <= me_csr_rena;
					wb_csr_wena <= me_csr_rena;
					wb_csr_op <= me_csr_op;
					wb_new_rs1_data <= me_new_rs1_data;
				end
				`STALL_KEEP: begin
				end
				`STALL_ZERO: begin
//					wb_alu_result <= `ZERO_WORD;
//					wb_mem_data <= `ZERO_WORD;
//					wb_mem_to_reg <= 1'b0;
//					wb_mem_ext_un <= 1'b0;
//					wb_mem_byte_enable <= 8'b0000_0000;
					wb_rd_wena <= 1'b0;
//					wb_rd_waddr <= 5'b00000;
					wb_pc <= `ZERO_WORD;
					//wb_inst <= 32'h0000_0000;
					wb_inst_valid <= 1'b0;
					wb_csr_rena <= 1'b0;
					wb_csr_wena <= 1'b0;
//					wb_csr_op <= 2'b00;
//					wb_new_rs1_data <= `ZERO_WORD;
				end
				default: begin	
//					wb_alu_result <= `ZERO_WORD;
//					wb_mem_data <= `ZERO_WORD;
//					wb_mem_to_reg <= 1'b0;
//					wb_mem_ext_un <= 1'b0;
//					wb_mem_byte_enable <= 8'b0000_0000;
					wb_rd_wena <= 1'b0;
//					wb_rd_waddr <= 5'b00000;
					wb_pc <= `ZERO_WORD;
				//	wb_inst <= 32'h0000_0000;
					wb_inst_valid <= 1'b0;
					wb_csr_rena <= 1'b0;
					wb_csr_wena <= 1'b0;
//					wb_csr_op <= 2'b00;
//					wb_new_rs1_data <= `ZERO_WORD;
				end
			endcase
		end
	end

endmodule
