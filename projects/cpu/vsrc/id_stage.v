//assume load and store are align

`include "defines.v"

module id_stage(
  	input wire rst,
  	input wire [31 : 0]inst,
  		
  	output wire rs1_r_ena,
  	output wire [4 : 0]rs1_r_addr,
  	output wire rs2_r_ena,
  	output wire [4 : 0]rs2_r_addr,
  	output wire rd_w_ena,
  	output wire [4 : 0]rd_w_addr,
  
	/* exe stage signal */
  	output wire [`ALU_OP_BUS] alu_op,
	output wire [`REG_BUS] imm,
	output wire alu_op1_src,
	output wire [1 : 0] alu_op2_src,
	output wire rs1_sign,			//only for mul
	output wire rs2_sign,			//only for mul
	/* branch and jump signal */
	output wire branch,
	output wire jump,
	output wire pc_src,

	/* mem stage signal */
	output wire mem_r_ena,
	output wire mem_w_ena,
	output wire [7 : 0] byte_enable,
	/* wb stage signal */
	output wire mem_ext_un,			
	output wire mem_to_reg,
	output wire csr_rena,
	output wire csr_wena,
	output wire [1 : 0] csr_op
);


wire [6  : 0]opcode;
wire [4  : 0]rd;
wire [2  : 0]func3;
wire [6  : 0]func7;
wire [4  : 0]rs1;
wire [4  : 0]rs2;
wire [11 : 0] csr_addr;

assign opcode = inst[6  :  0];
assign rd     = inst[11 :  7];
assign func3  = inst[14 : 12];
assign func7  = inst[31 : 25];
assign rs1    = inst[19 : 15];
assign rs2    = inst[24 : 20];
assign csr_addr = inst[31 : 20];

/* imm */
wire [`REG_BUS] immI = {{52{inst[31]}}, inst[31 : 20]};
wire [`REG_BUS] immS = {{52{inst[31]}}, inst[31 : 25], inst[11 : 7]};
wire [`REG_BUS] immB = {{52{inst[31]}}, inst[7] ,inst[30 : 25], inst[11 : 8], 1'b0};
wire [`REG_BUS] immU = {{32{inst[31]}}, inst[31 : 12], 12'b0};
wire [`REG_BUS] immJ = {{44{inst[31]}}, inst[19 : 12], inst[20], inst[30 : 21], 1'b0};

/* opcode */
wire opcode_imm = (opcode == `OP_IMM) ? 1'b1 : 1'b0;
wire opcode_imm32 = (opcode == `OP_IMM32) ? 1'b1 : 1'b0;
wire opcode_op = (opcode == `OP) ? 1'b1 : 1'b0;
wire opcode_op32 = (opcode == `OP32) ? 1'b1 : 1'b0;
wire opcode_lui = (opcode == `LUI) ? 1'b1 : 1'b0;
wire opcode_branch = (opcode == `BRANCH) ? 1'b1 : 1'b0;
wire opcode_jal = (opcode == `JAL) ? 1'b1 : 1'b0;
wire opcode_jalr = (opcode == `JALR) ? 1'b1 : 1'b0;
wire opcode_auipc = (opcode == `AUIPC) ? 1'b1 : 1'b0;
wire opcode_load = (opcode == `LOAD) ? 1'b1 : 1'b0;
wire opcode_store = (opcode == `STORE) ? 1'b1 : 1'b0;
wire opcode_system = (opcode == `SYSTEM) ? 1'b1 : 1'b0;
wire opcode_cus0 = (opcode == `CUS0) ? 1'b1 : 1'b0;

/* inst */
wire inst_lui = opcode_lui;
wire inst_auipc = opcode_auipc;
wire inst_jal = opcode_jal;
wire inst_jalr = opcode_jalr;

wire inst_beq = opcode_branch & (func3 == `FUN3_BEQ);
wire inst_bne = opcode_branch & (func3 == `FUN3_BNE);
wire inst_blt = opcode_branch & (func3 == `FUN3_BLT);
wire inst_bge = opcode_branch & (func3 == `FUN3_BGE);
wire inst_bltu = opcode_branch & (func3 == `FUN3_BLTU);
wire inst_bgeu = opcode_branch & (func3 == `FUN3_BGEU);

wire inst_lb = opcode_load & (func3 == `FUN3_LB);
wire inst_lh = opcode_load & (func3 == `FUN3_LH);
wire inst_lw = opcode_load & (func3 == `FUN3_LW);
wire inst_lbu = opcode_load & (func3 == `FUN3_LBU);
wire inst_lhu = opcode_load & (func3 == `FUN3_LHU);
wire inst_lwu = opcode_load & (func3 == `FUN3_LWU);
wire inst_ld = opcode_load & (func3 == `FUN3_LD);

wire inst_sb = opcode_store & (func3 == `FUN3_SB);
wire inst_sh = opcode_store & (func3 == `FUN3_SH);
wire inst_sw = opcode_store & (func3 == `FUN3_SW);
wire inst_sd = opcode_store & (func3 == `FUN3_SD);

wire inst_addi = opcode_imm & (func3 == `FUN3_ADDI);
wire inst_slti = opcode_imm & (func3 == `FUN3_SLTI);
wire inst_sltiu = opcode_imm & (func3 == `FUN3_SLTIU);
wire inst_xori = opcode_imm & (func3 == `FUN3_XORI);
wire inst_ori = opcode_imm & (func3 == `FUN3_ORI);
wire inst_andi = opcode_imm & (func3 == `FUN3_ANDI);
wire inst_slli = opcode_imm & (func3 == `FUN3_SL);
wire inst_srli = opcode_imm & (func3 == `FUN3_SR) & ~inst[30];
wire inst_srai = opcode_imm & (func3 == `FUN3_SR) & inst[30];

wire inst_add = opcode_op & (func3 == `FUN3_ADD_SUB) & ~(|func7);
wire inst_sub = opcode_op & (func3 == `FUN3_ADD_SUB) & (~inst[31] & inst[30] & ~inst[29] & ~inst[28] & ~inst[27] & ~inst[26] & ~inst[25]);
wire inst_sll = opcode_op & (func3 == `FUN3_SL) & ~(|func7);
wire inst_slt = opcode_op & (func3 == `FUN3_SLT) & ~(|func7);
wire inst_sltu = opcode_op & (func3 == `FUN3_SLTU) & ~(|func7);
wire inst_xor = opcode_op & (func3 == `FUN3_XOR) & ~(|func7);
wire inst_srl = opcode_op & (func3 == `FUN3_SR) & ~(|func7);
wire inst_sra = opcode_op & (func3 == `FUN3_SR) & (~inst[31] & inst[30] & ~inst[29] & ~inst[28] & ~inst[27] & ~inst[26] & ~inst[25]);
wire inst_or = opcode_op & (func3 == `FUN3_OR) & ~(|func7);
wire inst_and = opcode_op & (func3 == `FUN3_AND) & ~(|func7);

wire inst_addiw = opcode_imm32 & (func3 == `FUN3_ADDI);
wire inst_slliw = opcode_imm32 & (func3 == `FUN3_SL) & ~(|func7);
wire inst_srliw = opcode_imm32 & (func3 == `FUN3_SR) & ~(|func7);
wire inst_sraiw = opcode_imm32 & (func3 == `FUN3_SR) & (~inst[31] & inst[30] & ~inst[29] & ~inst[28] & ~inst[27] & ~inst[26] & ~inst[25]);
wire inst_addw = opcode_op32 & (func3 == `FUN3_ADD_SUB) & ~(|func7);
wire inst_subw = opcode_op32 & (func3 == `FUN3_ADD_SUB) &  (~inst[31] & inst[30] & ~inst[29] & ~inst[28] & ~inst[27] & ~inst[26] & ~inst[25]);
wire inst_sllw = opcode_op32 & (func3 == `FUN3_SL) & ~(|func7);
wire inst_srlw = opcode_op32 & (func3 == `FUN3_SR) & ~(|func7);
wire inst_sraw = opcode_op32 & (func3 == `FUN3_SR) & (~inst[31] & inst[30] & ~inst[29] & ~inst[28] & ~inst[27] & ~inst[26] & ~inst[25]);

//csr instructions
wire inst_csrrw = opcode_system & (func3 == `FUN3_CSRRW);
wire inst_csrrs = opcode_system & (func3 == `FUN3_CSRRS);
wire inst_csrrc = opcode_system & (func3 == `FUN3_CSRRC);
wire inst_csrrwi = opcode_system & (func3 == `FUN3_CSRRWI);
wire inst_csrrsi = opcode_system & (func3 == `FUN3_CSRRSI);
wire inst_csrrci = opcode_system & (func3 == `FUN3_CSRRCI);

// M extension
wire inst_mul = opcode_op & (func3 == `FUN3_MUL) & (func7 == `FUN7_M);
wire inst_mulh = opcode_op & (func3 == `FUN3_MULH) & (func7 == `FUN7_M);
wire inst_mulhsu = opcode_op & (func3 == `FUN3_MULHSU) & (func7 == `FUN7_M);
wire inst_mulhu = opcode_op & (func3 == `FUN3_MULHU) & (func7 == `FUN7_M);
wire inst_mulw = opcode_op32 & (func3 == `FUN3_MUL) & (func7 == `FUN7_M);

/* control signal */
assign rs1_sign = inst_mulh | inst_mulhsu;
assign rs2_sign = inst_mulh;
assign branch = opcode_branch;
assign jump = opcode_jal | opcode_jalr;
assign pc_src = opcode_jalr;		//1: from reg; 0: from pc

assign mem_to_reg = opcode_load;
assign mem_r_ena = opcode_load;
assign mem_w_ena = opcode_store;
assign mem_ext_un = inst_lbu | inst_lhu | inst_lwu;
assign byte_enable = ({8{inst_lb | inst_lbu | inst_sb}} & 8'b0000_0001)
					|({8{inst_lh | inst_lhu | inst_sh}} & 8'b0000_0011)
					|({8{inst_lw | inst_lwu | inst_sw}} & 8'b0000_1111)
					|({8{inst_ld | inst_sd}} & 8'b1111_1111);


assign rs1_r_addr = ( rst == 1'b1 ) ? 0 : rs1;
assign rs2_r_addr = ( rst == 1'b1 ) ? 0 : rs2;
assign rd_w_addr  = ( rst == 1'b1 ) ? 0 : rd;

assign rs1_r_ena = opcode_jalr | opcode_branch | opcode_imm | opcode_imm32 
		| opcode_op | opcode_op32 | opcode_store | opcode_load
		| inst_csrrw | ((inst_csrrc | inst_csrrs) & |rs1_r_addr);
assign rs2_r_ena = opcode_branch | opcode_store | opcode_op | opcode_op32;
assign rd_w_ena = opcode_lui | opcode_auipc | opcode_jal | opcode_jalr
		| opcode_load | opcode_op | opcode_op32 | opcode_imm | opcode_imm32
		| inst_csrrs | inst_csrrc | (inst_csrrw & |rd_w_addr);
assign alu_op1_src = opcode_auipc | opcode_jal | opcode_jalr;	//1: pc; 0: reg
assign alu_op2_src = ({2{opcode_lui | opcode_auipc | opcode_load | opcode_store | opcode_imm | opcode_imm32 | opcode_system}} & `OP2_IMM)
					|({2{opcode_jal | opcode_jalr}} & `OP2_4)
					|({2{opcode_op | opcode_op32 | opcode_branch}} & `OP2_REG);
assign imm = ({64{opcode_lui | opcode_auipc}} & immU)
			|({64{opcode_jal}} 				& immJ)
			|({64{opcode_branch}} 			& immB)
			|({64{opcode_jalr | opcode_load | opcode_imm | opcode_imm32 | opcode_system}} & immI)
			|({64{opcode_store}} & immS);

/* alu_op */
wire alu_add = inst_add | inst_addi | opcode_store | opcode_load | opcode_auipc
			| opcode_auipc | opcode_jal | opcode_jalr;
wire alu_slt = inst_slt | inst_slti;
wire alu_sltu = inst_sltu | inst_sltiu;
wire alu_xor = inst_xor | inst_xori;
wire alu_or = inst_or | inst_ori;
wire alu_and = inst_and | inst_andi;
wire alu_sll = inst_sll | inst_slli;
wire alu_srl = inst_srl | inst_srli;
wire alu_sra = inst_sra | inst_srai;
wire alu_sub = inst_sub;
wire alu_lui = inst_lui | opcode_system;		//csr need rs1 to be alu_result
wire alu_beq = inst_beq;
wire alu_bne = inst_bne;
wire alu_blt = inst_blt;
wire alu_bge = inst_bge;
wire alu_bltu = inst_bltu;
wire alu_bgeu = inst_bgeu;
wire alu_addw = inst_addw | inst_addiw; 
wire alu_subw = inst_subw;
wire alu_sllw = inst_sllw | inst_slliw;
wire alu_srlw = inst_srlw | inst_srliw;
wire alu_sraw = inst_sraw | inst_sraiw;
wire alu_mul = inst_mul;
wire alu_mulh = inst_mulh | inst_mulhsu | inst_mulhu;
wire alu_mulw = inst_mulw;

encoder32_5 Encoder32_5(.in({6'b0, alu_mulw, alu_mulh, alu_mul, alu_sraw, alu_srlw, alu_sllw, alu_subw, alu_addw, alu_bgeu, alu_bltu, alu_bge, alu_blt, alu_bne, alu_beq, alu_lui, alu_sub, alu_sra, alu_srl, alu_sll, alu_and, alu_or, alu_xor, alu_sltu, alu_slt, alu_add, 1'b0}), .out(alu_op));

/* csr signal */
wire [4 : 0] csr_uimm = rs1_r_addr;
assign csr_op = {2{opcode_system}} & inst[13 : 12];

assign csr_rena = (csr_op[1] & ~csr_op[0]) | (csr_op[1] & csr_op[1]) | (~csr_op[1] & csr_op[0] & (|rd_w_addr));
assign csr_wena = (csr_op[1] & ~csr_op[0] & (|csr_uimm)) | (csr_op[1] & csr_op[1] & (|csr_uimm)) | (~csr_op[1] & csr_op[0]);

endmodule