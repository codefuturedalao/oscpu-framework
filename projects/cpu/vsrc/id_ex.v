`include "defines.v"

module id_ex(
	input wire clk,
	input wire rst,
	input wire [1 : 0] stall,
	
	input wire [`REG_BUS] id_pc,
	input wire [`INST_BUS] id_inst,		//for difftest
	input wire id_inst_valid,
	input wire [4 : 0] id_rs1_addr,
	input wire [4 : 0] id_rs2_addr,
	input wire [`REG_BUS] id_rs1_data,
	input wire [`REG_BUS] id_rs2_data,
	input wire id_alu_op1_src,
	input wire [1 : 0] id_alu_op2_src,
	input wire [`REG_BUS] id_imm,
	input wire id_rd_wena,
	input wire [4 : 0] id_rd_waddr,
	input wire id_branch,
	input wire id_jump,
	input wire id_pc_src,
	input wire id_mem_rena,
	input wire id_mem_wena,
	input wire id_mem_ext_un,
	input wire id_mem_to_reg,
	input wire [7 : 0] id_mem_byte_enable, 
	input wire [`ALU_OP_BUS] id_alu_op,
	input wire id_csr_rena,
	input wire id_csr_wena,
	input wire [1 : 0] id_csr_op,
	input wire [11 : 0] id_csr_addr,
	input wire id_rs1_sign,
	input wire id_rs2_sign,
	input wire id_exception_flag,
	input wire [4 : 0] id_exception_cause,

	output reg [`REG_BUS] ex_pc,
	output reg [`INST_BUS] ex_inst,
	output reg ex_inst_valid,
	output reg [4 : 0] ex_rs1_addr,
	output reg [4 : 0] ex_rs2_addr,
	output reg [`REG_BUS] ex_rs1_data,
	output reg [`REG_BUS] ex_rs2_data,
	output reg ex_alu_op1_src,
	output reg [1 : 0] ex_alu_op2_src,
	output reg [`REG_BUS] ex_imm,
	output reg ex_rd_wena,
	output reg [4 : 0] ex_rd_waddr,
	output reg ex_branch,
	output reg ex_jump,
	output reg ex_pc_src,
	output reg ex_mem_rena,
	output reg ex_mem_wena,
	output reg ex_mem_ext_un,
	output reg ex_mem_to_reg,
	output reg [7 : 0] ex_mem_byte_enable, 
	output reg [`ALU_OP_BUS] ex_alu_op,
	output reg ex_csr_rena,
	output reg ex_csr_wena,
	output reg [1 : 0] ex_csr_op,
	output reg [11 : 0] ex_csr_addr,
	output reg ex_rs1_sign,
	output reg ex_rs2_sign,
	output reg ex_exception_flag,
	output reg [4 : 0] ex_exception_cause
);

always
	@(posedge clk) begin
		if(rst == 1'b1) begin
			ex_pc <= `ZERO_WORD;
			ex_rs1_data <= `ZERO_WORD;
			ex_rs2_data <= `ZERO_WORD;
			ex_rs1_addr <= 5'b00000;
			ex_rs2_addr <= 5'b00000;
			ex_alu_op1_src <= 1'b0;
			ex_alu_op2_src <= 2'b00;
			ex_imm <= `ZERO_WORD;
			ex_rd_wena <= `REG_WDISABLE;
			ex_rd_waddr <= 5'b00000;
			ex_branch <= 1'b0;
			ex_jump <= 1'b0;
			ex_pc_src <= `NEXTPC_PC;
			ex_mem_rena <= 1'b0;
			ex_mem_wena <= 1'b0;
			ex_mem_ext_un <= 1'b0;
			ex_mem_to_reg <= 1'b0;
			ex_mem_byte_enable <= 8'b0000_0000;
			ex_alu_op <= `ALU_ZERO;
			ex_inst <= 32'h0000_0000;
			ex_inst_valid <= 1'b0;
			ex_csr_rena <= 1'b0;
			ex_csr_wena <= 1'b0;
			ex_csr_op <= 2'b00;
			ex_csr_addr <= 12'h000;
			ex_rs1_sign <= 1'b0;
			ex_rs2_sign <= 1'b0;
			ex_exception_flag <= 1'b0;
			ex_exception_cause <= 5'b00000;
		end	
		else begin
			case(stall)
				`STALL_NEXT: begin
					ex_pc <= id_pc;
					ex_rs1_data <= id_rs1_data;
					ex_rs2_data <= id_rs2_data;
					ex_rs1_addr <= id_rs1_addr;
					ex_rs2_addr <= id_rs2_addr;
					ex_alu_op1_src <= id_alu_op1_src;
					ex_alu_op2_src <= id_alu_op2_src;
					ex_imm <= id_imm;
					ex_rd_wena <= id_rd_wena;
					ex_rd_waddr <= id_rd_waddr;
					ex_branch <= id_branch;
					ex_jump <= id_jump;
					ex_pc_src <= id_pc_src;
					ex_mem_rena <= id_mem_rena;
				 	ex_mem_wena <= id_mem_wena;
					ex_mem_ext_un <= id_mem_ext_un;
					ex_mem_to_reg <= id_mem_to_reg;
					ex_mem_byte_enable <= id_mem_byte_enable;
					ex_alu_op <= id_alu_op;
					ex_inst <= id_inst;
					ex_inst_valid <= id_inst_valid;
					ex_csr_rena <= id_csr_rena;
					ex_csr_wena <= id_csr_wena;
					ex_csr_op <= id_csr_op;
					ex_csr_addr <= id_csr_addr;
					ex_rs1_sign <= id_rs1_sign;
					ex_rs2_sign <= id_rs2_sign;
					ex_exception_flag <= id_exception_flag;
					ex_exception_cause <= id_exception_cause; 
				end
				`STALL_KEEP: begin
				end
				`STALL_ZERO: begin
					ex_pc <= `ZERO_WORD;
				/*	ex_rs1_data <= `ZERO_WORD;
					ex_rs2_data <= `ZERO_WORD;
					ex_rs1_addr <= 5'b00000;
					ex_rs2_addr <= 5'b00000;
					ex_alu_op1_src <= 1'b0;
					ex_alu_op2_src <= 2'b00;
					ex_imm <= `ZERO_WORD;
				*/
					ex_rd_wena <= `REG_WDISABLE;
				//	ex_rd_waddr <= 5'b00000;
					ex_branch <= 1'b0;
					ex_jump <= 1'b0;
				//	ex_pc_src <= `NEXTPC_PC;
					ex_mem_rena <= 1'b0;
					ex_mem_wena <= 1'b0;
				/*	ex_mem_ext_un <= 1'b0;
					ex_mem_to_reg <= 1'b0;
					ex_mem_byte_enable <= 8'b0000_0000;
					ex_alu_op <= `ALU_ZERO;
				*/
				//	ex_inst <= 32'h0000_0000;
					ex_inst_valid <= 1'b0;
					ex_csr_rena <= 1'b0;
					ex_csr_wena <= 1'b0;
					ex_exception_flag <= 1'b0;
//					ex_exception_cause <= 5'b00000;
				//	ex_csr_op <= 2'b00;
				//	ex_rs1_sign <= 1'b0;
				//	ex_rs2_sign <= 1'b0;
				end
				default: begin
					ex_pc <= `ZERO_WORD;
				/*	ex_rs1_data <= `ZERO_WORD;
					ex_rs2_data <= `ZERO_WORD;
					ex_rs1_addr <= 5'b00000;
					ex_rs2_addr <= 5'b00000;
					ex_alu_op1_src <= 1'b0;
					ex_alu_op2_src <= 2'b00;
					ex_imm <= `ZERO_WORD;
				*/
					ex_rd_wena <= `REG_WDISABLE;
				//	ex_rd_waddr <= 5'b00000;
					ex_branch <= 1'b0;
					ex_jump <= 1'b0;
				//	ex_pc_src <= `NEXTPC_PC;
					ex_mem_rena <= 1'b0;
					ex_mem_wena <= 1'b0;
				/*	ex_mem_ext_un <= 1'b0;
					ex_mem_to_reg <= 1'b0;
					ex_mem_byte_enable <= 8'b0000_0000;
					ex_alu_op <= `ALU_ZERO;
				*/
				//	ex_inst <= 32'h0000_0000;
					ex_inst_valid <= 1'b0;
					ex_csr_rena <= 1'b0;
					ex_csr_wena <= 1'b0;

					ex_exception_flag <= 1'b0;
//					ex_exception_cause <= 5'b00000;
				//	ex_csr_op <= 2'b00;
				//	ex_rs1_sign <= 1'b0;
				//	ex_rs2_sign <= 1'b0;
				end
			endcase
		end
	end	

endmodule

