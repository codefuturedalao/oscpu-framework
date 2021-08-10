`include "defines.v"

module exe_stage(
  	input wire rst,
	input wire [`ALU_OP_BUS] alu_op,
	input wire pc_src,
	input wire [`REG_BUS] pc,
	input wire alu_op1_src,
	input wire [1 : 0] alu_op2_src,
	input wire [`REG_BUS] imm,
	
	input wire [1 : 0] rs1_src,
	input wire [1 : 0] rs2_src,
	input wire [`REG_BUS] ex_rs1_data,
	input wire [`REG_BUS] ex_rs2_data,
	input wire [`REG_BUS] me_alu_result,
	input wire [`REG_BUS] wb_rd_data,
  
	output wire [`REG_BUS] new_rs1_data,
	output wire [`REG_BUS] new_rs2_data,
  	output reg  [`REG_BUS] alu_result,
	output wire [`REG_BUS] target_pc,
	output reg b_flag			//indicate branch is successful or not
);

wire overflow;
wire sign;
wire cout;
wire carry;
wire zero;
reg cin;
reg [`REG_BUS] op1_add;
reg [`REG_BUS] op2_add; 
wire [`REG_BUS] result_add; 

wire [`REG_BUS]op1;
wire [`REG_BUS]op2;
//wire [`REG_BUS]new_rs1_data;
//wire [`REG_BUS]new_rs2_data;

/* select new_rs1_data and new_rs2_data to solve data hazard */
rs1_mux Rs1_mux(.ex_rs1_data(ex_rs1_data), .me_alu_result(me_alu_result), .wb_rd_data(wb_rd_data), .rs1_src(rs1_src), .new_rs1_data(new_rs1_data));
rs2_mux Rs2_mux(.ex_rs2_data(ex_rs2_data), .me_alu_result(me_alu_result), .wb_rd_data(wb_rd_data), .rs2_src(rs2_src), .new_rs2_data(new_rs2_data)); 
/* select op1 and op2 */
op1_mux Op1_mux(.new_rs1_data(new_rs1_data), .pc(pc), .alu_op1_src(alu_op1_src), .op1(op1));
op2_mux Op2_mux(.new_rs2_data(new_rs2_data), .imm(imm), .alu_op2_src(alu_op2_src), .op2(op2));

wire alu_add, alu_slt, alu_sltu, alu_xor, alu_or, alu_and, alu_sll, alu_srl, alu_sra, alu_sub, alu_lui, alu_beq, alu_bne, alu_blt;
wire alu_bge, alu_bltu, alu_bgeu, alu_addw, alu_subw, alu_sllw, alu_srlw, alu_sraw;

decoder5_32 Decoder5_32(.in(alu_op), .out({9'b0, alu_sraw, alu_srlw, alu_sllw, alu_subw, alu_addw, alu_bgeu, alu_bltu, alu_bge, alu_blt, alu_bne, alu_beq, alu_lui, alu_sub, alu_sra, alu_srl, alu_sll, alu_and, alu_or, alu_xor, alu_sltu, alu_slt, alu_add, 1'b0}));

/* add or sub */
assign op1_add = op1;
assign op2_add = ((alu_sub | alu_subw | alu_slt | alu_sltu | alu_beq | alu_bne | alu_blt | alu_bge | alu_bltu | alu_bgeu) == 1'b1) ? ~op2 : op2;
assign cin = ((alu_sub | alu_subw | alu_slt | alu_sltu | alu_beq | alu_bne | alu_blt | alu_bge | alu_bltu | alu_bgeu) == 1'b1) ? 1'b1: 1'b0;
adder64 myadder(op1_add, op2_add, cin, result_add, overflow, sign, cout, carry, zero);
				

/* calculate alu_result */
wire [`REG_BUS] sll_result = op1 << op2[5 : 0];
wire [31 : 0] sll_result32 = op1[31:0] << op2[4 : 0];
wire [`REG_BUS] srl_result = op1 >> op2[5 : 0];
wire [31 : 0] srl_result32 = op1[31 : 0] >> op2[4 : 0];
wire [`REG_BUS] sra_result = (op1 >> op2[5:0]) | (op1[63] ? ~({64{1'b1}} >> op2[5:0]) : {64'b0});
wire [31 : 0] sra_result32 = (op1[31 : 0] >> op2[4:0]) | (op1[31] ? ~({32{1'b1}} >> op2[4:0]) : {32'b0});
wire [`REG_BUS] xor_result = op1 ^ op2;
wire [`REG_BUS] or_result = op1 | op2;
wire [`REG_BUS] and_result = op1 & op2;

assign alu_result = ({64{alu_add | alu_sub}} & result_add)
				|	({64{alu_addw | alu_subw}} & ({{32{result_add[31]}}, result_add[31 : 0]}))
				|	({64{alu_slt}} 	& {63'b0 , sign ^ overflow})
				|	({64{alu_sltu}}	& {63'b0, carry})
				|	({64{alu_xor}}  & xor_result)
				|	({64{alu_or}}  	& or_result)
				|	({64{alu_and}}  & and_result)
				|	({64{alu_sll}} 	& sll_result)
				|	({64{alu_srl}} 	& srl_result)
				|	({64{alu_sra}} 	& sra_result)
				|   ({64{alu_sllw}} & {{32{sll_result32[31]}}, sll_result32[31:0]})
				|   ({64{alu_srlw}} & {{32{srl_result32[31]}}, srl_result32[31:0]})
				|   ({64{alu_sraw}} & {{32{sra_result32[31]}}, sra_result32[31:0]})
				|	({64{alu_lui}}  & op2);

/* generate b_flag */
assign b_flag = (alu_beq & zero) | (alu_bne & ~zero) | (alu_blt & (sign ^ overflow)) | (alu_bge & (~(sign ^ overflow)))
			|	(alu_bltu & carry) | (alu_bgeu & ~carry);

/* calculate traget instruction's pc for branch and jump */
wire [`REG_BUS] pc_op1;
wire [`REG_BUS] target_pc_tmp;
assign pc_op1 = (pc_src == 1'b1) ? new_rs1_data : pc;
assign target_pc = {target_pc_tmp[63:1], pc_src == 1 ? 1'b0 : target_pc_tmp[0]};		//JALR make the least significant bit zero
adder64 Pcadder(.op1(pc_op1), .op2(imm), .cin(0), .result(target_pc_tmp), .zero(), .sign(), .overflow(), .carry(), .cout());


endmodule
