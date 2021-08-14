`timescale 1ns / 1ps

`include "defines.v"


module rvcpu(
	input wire            clk,
	input wire            rst,
  	input wire  [63 : 0]  inst_rdata,
		  
	output wire [63 : 0]  inst_addr, 
	output wire           inst_ena,

	input wire  [63 : 0]  mem_rdata,
	 
	output wire [63 : 0]  mem_raddr, 
	output wire           mem_rena,

	output wire  [63 : 0]  mem_wdata,
			  
	output wire [63 : 0]  mem_waddr, 
	output wire [63 : 0]  mem_wmask, 
	output wire           mem_wena,

	output wire diff_wb_rd_wena,
	output wire [4 : 0] diff_wb_rd_waddr,
	output wire [`REG_BUS] diff_wb_rd_data,
	output wire [`REG_BUS] diff_wb_pc,
	output wire [`REG_BUS] diff_wb_inst,
	output wire [`REG_BUS] regs[0 : 31]
);

// hazard_unit
wire [1 : 0] pc_stall;
wire [1 : 0] if_id_stall;
wire [1 : 0] id_ex_stall;
wire [1 : 0] ex_me_stall;
wire [1 : 0] me_wb_stall;


/* if stage */
wire [`REG_BUS] new_pc;
wire [`REG_BUS] if_pc;
wire [`INST_BUS] if_inst;
//wire inst_ena;
assign inst_addr = if_pc;
assign if_inst = if_pc[2] ? inst_rdata[63 : 32] : inst_rdata[31 : 0];

if_stage If_stage(
  	.clk(clk),
  	.rst(rst),
	.new_pc(new_pc),
	.stall(pc_stall),
  
  	.inst_addr(if_pc),
  	.inst_ena(inst_ena)
);

/* if_id flip flop */
wire [`INST_BUS] id_inst;
wire [`REG_BUS] id_pc;

if_id If_id(
	.clk(clk),
	.rst(rst),
	.if_inst(if_inst),
	.if_pc(if_pc),
	.stall(if_id_stall),
	
	.id_inst(id_inst),
	.id_pc(id_pc)
);

/* id stage */
// id_stage -> regfile
wire id_rs1_rena;
wire [4 : 0] id_rs1_raddr;
wire id_rs2_rena;
wire [4 : 0] id_rs2_raddr;
// id_stage -> exe_stage
wire [`ALU_OP_BUS] id_alu_op;
wire [`REG_BUS] id_imm;
wire id_alu_op1_src;
wire [1 : 0] id_alu_op2_src;
wire id_branch;
wire id_jump;
wire id_pc_src;
wire id_rs1_sign;
wire id_rs2_sign;
// id_stage -> mem_stage
wire id_mem_rena;
wire id_mem_wena;
wire id_mem_to_reg;
wire id_mem_ext_un;
wire [7 : 0] id_mem_byte_enable;
// id_stage -> wb_stage
wire id_rd_wena;
wire [4 : 0] id_rd_waddr;
wire id_csr_rena;
wire id_csr_wena;
wire [1 : 0] id_csr_op;
//wire [4 : 0] csr_uimm;


id_stage Id_stage(
  	.rst(rst),
  	.inst(id_inst),
  
  	.rs1_r_ena(id_rs1_rena),
  	.rs1_r_addr(id_rs1_raddr),
  	.rs2_r_ena(id_rs2_rena),
  	.rs2_r_addr(id_rs2_raddr),
  	.rd_w_ena(id_rd_wena),
  	.rd_w_addr(id_rd_waddr),

  	.alu_op(id_alu_op),
	.imm(id_imm),
	.alu_op1_src(id_alu_op1_src),
	.alu_op2_src(id_alu_op2_src),
	.rs1_sign(id_rs1_sign),
	.rs2_sign(id_rs2_sign),
	.branch(id_branch),
	.jump(id_jump),
	.pc_src(id_pc_src),
	.mem_r_ena(id_mem_rena),
	.mem_w_ena(id_mem_wena),
	.byte_enable(id_mem_byte_enable),
	.mem_ext_un(id_mem_ext_un),
	.mem_to_reg(id_mem_to_reg),
	.csr_rena(id_csr_rena),
	.csr_wena(id_csr_wena),
	.csr_op(id_csr_op)
);

// wb_stage -> regfile
wire wb_rd_wena;
wire [4 : 0] wb_rd_waddr;
wire [`REG_BUS]wb_rd_data;
// regfile -> id_ex
wire [`REG_BUS] id_rs1_data;
wire [`REG_BUS] id_rs2_data;
// regfile -> difftest
//wire [`REG_BUS] regs[0 : 31];


regfile Regfile(
  .clk(clk),
  .rst(rst),
  .w_addr(wb_rd_waddr),
  .w_data(wb_rd_data),
  .w_ena(wb_rd_wena),
  
  .r_addr1(id_rs1_raddr),
  .r_data1(id_rs1_data),
  .r_ena1(id_rs1_rena),
  .r_addr2(id_rs2_raddr),
  .r_data2(id_rs2_data),
  .r_ena2(id_rs2_rena),

  .regs_o(regs)
);

wire ex_mem_rena;
wire [4 : 0] ex_rd_waddr;
wire [4 : 0] me_rd_waddr;
wire transfer;
wire ex_csr_rena;
wire me_csr_rena;
wire exe_stall_req;

hazard_unit Hazard_unit(
	.ex_mem_rena(ex_mem_rena),
	.ex_rd_waddr(ex_rd_waddr),
	.me_rd_waddr(me_rd_waddr),
	.ex_csr_rena(ex_csr_rena),
	.me_csr_rena(me_csr_rena),
	.id_rs1_rena(id_rs1_rena),	
	.id_rs1_addr(id_rs1_raddr),
	.id_rs2_rena(id_rs2_rena),
	.id_rs2_addr(id_rs2_raddr),
	.transfer(transfer),
	.exe_stall_req(exe_stall_req),
	
	.pc_stall(pc_stall),
	.if_id_stall(if_id_stall),
	.id_ex_stall(id_ex_stall),
	.ex_me_stall(ex_me_stall),
	.me_wb_stall(me_wb_stall)
);
	

/* id_ex flip flop */
wire [`REG_BUS] ex_pc;
wire [`INST_BUS] ex_inst;
wire [4 : 0] ex_rs1_addr;
wire [4 : 0] ex_rs2_addr;
wire [`REG_BUS] ex_rs1_data;
wire [`REG_BUS] ex_rs2_data;
wire ex_alu_op1_src;
wire [1 : 0] ex_alu_op2_src;
wire [`REG_BUS] ex_imm;
wire ex_rd_wena;
wire ex_branch;
wire ex_jump;
wire ex_pc_src;
wire ex_mem_wena;
wire ex_mem_ext_un;
wire ex_mem_to_reg;
wire [7 : 0] ex_mem_byte_enable; 
wire [`ALU_OP_BUS] ex_alu_op;
//wire ex_csr_rena;
wire ex_csr_wena;
wire [1 : 0] ex_csr_op;
wire ex_rs1_sign;
wire ex_rs2_sign;

id_ex Id_ex(
	.clk(clk),
	.rst(rst),
	.stall(id_ex_stall),
	
	.id_pc(id_pc),
	.id_inst(id_inst),
	.id_rs1_addr(id_rs1_raddr),
	.id_rs2_addr(id_rs2_raddr),
	.id_rs1_data(id_rs1_data),
	.id_rs2_data(id_rs2_data),
	.id_alu_op1_src(id_alu_op1_src),
	.id_alu_op2_src(id_alu_op2_src),
	.id_imm(id_imm),
	.id_rd_wena(id_rd_wena),
	.id_rd_waddr(id_rd_waddr),
	.id_branch(id_branch),
	.id_jump(id_jump),
	.id_pc_src(id_pc_src),
	.id_mem_rena(id_mem_rena),
	.id_mem_wena(id_mem_wena),
	.id_mem_ext_un(id_mem_ext_un),
	.id_mem_to_reg(id_mem_to_reg),
	.id_mem_byte_enable(id_mem_byte_enable),
	.id_alu_op(id_alu_op),
	.id_csr_rena(id_csr_rena),
	.id_csr_wena(id_csr_wena),
	.id_csr_op(id_csr_op),
	.id_rs1_sign(id_rs1_sign),
	.id_rs2_sign(id_rs2_sign),

	.ex_pc(ex_pc),
	.ex_inst(ex_inst),
	.ex_rs1_addr(ex_rs1_addr),
	.ex_rs2_addr(ex_rs2_addr),
	.ex_rs1_data(ex_rs1_data),
	.ex_rs2_data(ex_rs2_data),
	.ex_alu_op1_src(ex_alu_op1_src),
	.ex_alu_op2_src(ex_alu_op2_src),
	.ex_imm(ex_imm),
	.ex_rd_wena(ex_rd_wena),
	.ex_rd_waddr(ex_rd_waddr),
	.ex_branch(ex_branch),
	.ex_jump(ex_jump),
	.ex_pc_src(ex_pc_src),
	.ex_mem_rena(ex_mem_rena),
	.ex_mem_wena(ex_mem_wena),
	.ex_mem_ext_un(ex_mem_ext_un),
	.ex_mem_to_reg(ex_mem_to_reg),
	.ex_mem_byte_enable(ex_mem_byte_enable),
	.ex_alu_op(ex_alu_op),
	.ex_csr_rena(ex_csr_rena),
	.ex_csr_wena(ex_csr_wena),
	.ex_csr_op(ex_csr_op),
	.ex_rs1_sign(ex_rs1_sign),
	.ex_rs2_sign(ex_rs2_sign)
);

/* exe stage */
// mem_stage -> exe_stage
wire [`REG_BUS] me_alu_result;

// exe_stage -> mem stage
wire ex_b_flag;
wire [`REG_BUS] ex_new_rs1_data;	//for csr calculate
wire [`REG_BUS] ex_new_rs2_data;	//for store 
wire [`REG_BUS] ex_target_pc;	//for branch and jump
wire [`REG_BUS] ex_alu_result;

/* forward unit */
wire me_rd_wena;
wire [1 : 0] rs1_src;
wire [1 : 0] rs2_src;

forward_unit Forward_unit(
	.ex_rs1_addr(ex_rs1_addr),
	.ex_rs2_addr(ex_rs2_addr),
	.me_rd_wena(me_rd_wena),
	.me_rd_waddr(me_rd_waddr),
	.wb_rd_wena(wb_rd_wena),
	.wb_rd_waddr(wb_rd_waddr),

	.rs1_src(rs1_src),
	.rs2_src(rs2_src)
);

//wire mul_ready;
//wire mul_valid;
wire [127 : 0] mul_result;
wire div_valid;
wire div_32;
wire div_sign;
wire div_ready;
wire [127 : 0] div_result;

exe_stage Exe_stage(
	.rst(rst),
  	.alu_op(ex_alu_op),
	.pc_src(ex_pc_src),
	.pc(ex_pc),
	.alu_op1_src(ex_alu_op1_src),
	.alu_op2_src(ex_alu_op2_src),
	.imm(ex_imm),
	
	.rs1_src(rs1_src),
	.rs2_src(rs2_src),
	.ex_rs1_data(ex_rs1_data),
	.ex_rs2_data(ex_rs2_data),
	.me_alu_result(me_alu_result),
	.wb_rd_data(wb_rd_data),
	

	.mul_result(mul_result),
	//.mul_ready(mul_ready),
	//.mul_valid(mul_valid),
	.div_result(div_result),
	.div_ready(div_ready),
	.div_valid(div_valid),
	.div_32(div_32),

	.stall_req(exe_stall_req),
	.new_rs1_data(ex_new_rs1_data),
	.new_rs2_data(ex_new_rs2_data),
	.alu_result(ex_alu_result),
	.target_pc(ex_target_pc),
	.b_flag(ex_b_flag)
);
//may be i can define a macro to use multicycle or singcycle
/*

booth2_mul Booth2_mul(
	.clk(clk),
	.rst(rst),
	.valid(mul_valid),
	.rs1_sign(ex_rs1_sign),
	.rs2_sign(ex_rs2_sign),
	.rs1_data(ex_new_rs1_data),
	.rs2_data(ex_new_rs2_data),

	.ready(mul_ready),
	.mul_result(mul_result)
);
*/
wallace_mul Wallace_mul(
	.rs1_sign(ex_rs1_sign),
	.rs2_sign(ex_rs2_sign),
	.rs1_data(ex_new_rs1_data),
	.rs2_data(ex_new_rs2_data),
	
	.mul_result(mul_result)
);

multiCycle_div MultiCycle_div(
	.clk(clk),
	.rst(rst),
	.valid(div_valid),
	.div_sign(ex_rs1_sign | ex_rs2_sign),
	.div_32(div_32),
	.rs1_data(ex_new_rs1_data),
	.rs2_data(ex_new_rs2_data),
	
	.ready(div_ready),
	.div_result(div_result)
);
	
/* ex_me flip flop */
wire [`REG_BUS] me_target_pc;
wire me_branch;
wire me_jump;
wire me_b_flag;

wire me_mem_rena;
wire me_mem_wena;
wire me_mem_ext_un;
wire me_mem_to_reg;
wire [7 : 0] me_mem_byte_enable; 
//wire [`REG_BUS] me_alu_result;
wire [`REG_BUS] me_new_rs1_data;
wire [`REG_BUS] me_new_rs2_data;
wire [`REG_BUS] me_pc;
wire [`INST_BUS] me_inst;
//wire me_csr_rena;
wire me_csr_wena;
wire [1 : 0] me_csr_op;

ex_me Ex_me(
	.clk(clk),
	.rst(rst),
	.stall(ex_me_stall),
	
	.ex_target_pc(ex_target_pc),
	.ex_branch(ex_branch),
	.ex_jump(ex_jump),
	.ex_b_flag(ex_b_flag),
	.ex_mem_rena(ex_mem_rena),
	.ex_mem_wena(ex_mem_wena),
	.ex_mem_ext_un(ex_mem_ext_un),
	.ex_mem_to_reg(ex_mem_to_reg),
	.ex_mem_byte_enable(ex_mem_byte_enable),
	.ex_alu_result(ex_alu_result),
	.ex_new_rs1_data(ex_new_rs1_data),
	.ex_new_rs2_data(ex_new_rs2_data),
	.ex_rd_wena(ex_rd_wena),
	.ex_rd_waddr(ex_rd_waddr),
	.ex_pc(ex_pc),
	.ex_inst(ex_inst),
	.ex_csr_rena(ex_csr_rena),
	.ex_csr_wena(ex_csr_wena),
	.ex_csr_op(ex_csr_op),
	
	.me_target_pc(me_target_pc),
	.me_branch(me_branch),
	.me_jump(me_jump),
	.me_b_flag(me_b_flag),
	.me_mem_rena(me_mem_rena),
	.me_mem_wena(me_mem_wena),
	.me_mem_ext_un(me_mem_ext_un),
	.me_mem_to_reg(me_mem_to_reg),
	.me_mem_byte_enable(me_mem_byte_enable),
	.me_alu_result(me_alu_result),
	.me_new_rs1_data(me_new_rs1_data),
	.me_new_rs2_data(me_new_rs2_data),
	.me_rd_wena(me_rd_wena),
	.me_rd_waddr(me_rd_waddr),
	.me_pc(me_pc),
	.me_inst(me_inst),
	.me_csr_rena(me_csr_rena),
	.me_csr_wena(me_csr_wena),
	.me_csr_op(me_csr_op)	

);

/* mem stage */
pc_mux Pc_mux(
	.old_pc(if_pc),	
	.branch(me_branch),
	.jump(me_jump),
	.b_flag(me_b_flag),
	.target_pc(me_target_pc),
	
	.transfer(transfer),
	.new_pc(new_pc)
);


// Access memory
//reg [`REG_BUS] inst_rdata;
wire [`REG_BUS] me_mem_waddr;
wire [`REG_BUS] me_mem_raddr;
wire [`REG_BUS] me_mem_rdata;

wire [7 : 0] byte_en_new;

// waddr is same as raddr
assign me_mem_waddr = me_alu_result;
assign me_mem_raddr = me_alu_result;
wire [5 : 0] shift_bit = me_alu_result[2:0] << 3;

assign byte_en_new = me_mem_byte_enable << me_alu_result[2:0];

assign mem_rena = me_mem_rena;
assign mem_raddr = me_mem_raddr;
assign me_mem_rdata = mem_rdata;

assign mem_wena = me_mem_wena;
assign mem_wdata = me_new_rs2_data << shift_bit;
assign mem_waddr = me_mem_waddr;
assign mem_wmask = { {8{byte_en_new[7]}},
                {8{byte_en_new[6]}},
                {8{byte_en_new[5]}},
                {8{byte_en_new[4]}},
                {8{byte_en_new[3]}},
                {8{byte_en_new[2]}},
                {8{byte_en_new[1]}},
                {8{byte_en_new[0]}}};

/* me_wb flip flop */
wire [`REG_BUS] wb_alu_result;	
wire [`REG_BUS] wb_mem_data;
wire wb_mem_to_reg;
wire wb_mem_ext_un;
wire [7 : 0] wb_mem_byte_enable;
wire [`REG_BUS] wb_pc;
wire [`INST_BUS] wb_inst;
wire wb_csr_rena;
wire wb_csr_wena;
wire [1 : 0] wb_csr_op;
wire [`REG_BUS] wb_new_rs1_data;

me_wb Me_wb(
	.clk(clk),
	.rst(rst),
	.stall(me_wb_stall),

	.me_alu_result(me_alu_result),
	.me_mem_data(me_mem_rdata),
	.me_mem_to_reg(me_mem_to_reg),
	.me_mem_ext_un(me_mem_ext_un),
	.me_mem_byte_enable(me_mem_byte_enable),
	.me_rd_wena(me_rd_wena),
	.me_rd_waddr(me_rd_waddr),
	.me_pc(me_pc),
	.me_inst(me_inst),
	.me_csr_rena(me_csr_rena),
	.me_csr_wena(me_csr_wena),
	.me_csr_op(me_csr_op),
	.me_new_rs1_data(me_new_rs1_data),
	
	.wb_alu_result(wb_alu_result),
	.wb_mem_data(wb_mem_data),
	.wb_mem_to_reg(wb_mem_to_reg),
	.wb_mem_ext_un(wb_mem_ext_un),
	.wb_mem_byte_enable(wb_mem_byte_enable),
	.wb_rd_wena(wb_rd_wena),
	.wb_rd_waddr(wb_rd_waddr),
	.wb_pc(wb_pc),
	.wb_inst(wb_inst),
	.wb_csr_rena(wb_csr_rena),
	.wb_csr_wena(wb_csr_wena),
	.wb_csr_op(wb_csr_op),
	.wb_new_rs1_data(wb_new_rs1_data)
);

/* wb stage */
assign diff_wb_rd_wena = wb_rd_wena;
assign diff_wb_rd_waddr = wb_rd_waddr;
assign diff_wb_rd_data = wb_rd_data;
assign diff_wb_pc = wb_pc;
assign diff_wb_inst = wb_inst;

wire [63 : 0] csr_data;
rd_wmux Rd_wmux(
	.alu_result(wb_alu_result),
	.mem_data(wb_mem_data),
	.csr_data(csr_data),
	.mem_to_reg(wb_mem_to_reg),
	.mem_ext_un(wb_mem_ext_un),
	.byte_enable(wb_mem_byte_enable),
	.csr_rena(wb_csr_rena),
	
	.rd_wdata(wb_rd_data)
);


csr Csr(
	.clk(clk),
	.rst(rst),
	.csr_addr(wb_alu_result[11 : 0]),
	.csr_rena(wb_csr_rena),
	.csr_wena(wb_csr_wena),
	.csr_op(wb_csr_op),
	.rs1_data(wb_new_rs1_data),

	.csr_data(csr_data)
);



endmodule
