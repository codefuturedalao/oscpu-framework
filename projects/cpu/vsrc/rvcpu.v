`timescale 1ns / 1ps

`include "defines.v"
//`define RISCV_M


module rvcpu(
	input wire            clk,
	input wire            rst,


	input wire time_irq,
	input wire sip,

	/* if stage */
	input wire if_ready,
	input wire if_dvalid,
	input wire if_dlast,
    input wire [1 : 0] if_resp,
    input wire [`REG_BUS] if_data_read,
    output wire if_valid,
    output wire [`REG_BUS] if_addr,
    output wire [2 : 0] if_size,

	/* mem stage */
	input wire mem_rready,
	input wire mem_dvalid,
	input wire mem_dlast,
	input wire [1 : 0] mem_rresp,
	input wire [1 : 0] mem_wresp,
	input wire  [`REG_BUS]  mem_data_read,
	output wire  [`CACHE_BLOCK_DATA_WIDTH - 1 : 0]  mem_data_write,
	output wire mem_rvalid,
	output wire mem_wvalid,
	input wire mem_wready,
	//output wire [1 : 0] mem_req,
	output wire [`REG_BUS]  mem_raddr, 
	output wire [`REG_BUS]  mem_waddr, 
	output wire [2 : 0]  mem_rsize, 
	output wire [2 : 0]  mem_wsize, 
	

	output wire diff_wb_rd_wena,
	output wire [4 : 0] diff_wb_rd_waddr,
	output wire [`REG_BUS] diff_wb_rd_data,
	output wire [`REG_BUS] diff_wb_pc,
	output wire [`REG_BUS] diff_wb_inst,
	output wire diff_wb_inst_valid,
	output wire [`REG_BUS] regs[0 : 31],


	output wire uart_valid,
	output wire [7 : 0] uart_ch,
	output wire interrupt,

	output wire [`MXLEN-1 : 0] diff_mscratch,
	output wire [`MXLEN-1 : 0] diff_mstatus,
	output wire [`MXLEN-1 : 0] diff_sstatus,
	output wire [`MXLEN-1 : 0] diff_mcause,
	output wire [`MXLEN-1 : 0] diff_mepc,
	output wire [`MXLEN-1 : 0] diff_mtvec,
	output wire [`MXLEN-1 : 0] diff_mip,
	output wire [`MXLEN-1 : 0] diff_mie
);

// hazard_unit
wire [1 : 0] pc_stall;
wire [1 : 0] if_id_stall;
wire [1 : 0] id_ex_stall;
wire [1 : 0] ex_me_stall;
wire [1 : 0] me_wb_stall;


/* if stage */
wire [`REG_BUS] new_pc;
wire [`REG_BUS] pc_minus_4;
wire [`REG_BUS] if_pc;
wire [`REG_BUS] inst_addr;
wire [`INST_BUS] if_inst;
wire if_inst_valid;		
//assign if_pc = inst_addr;
assign if_pc = pc_minus_4;
//wire inst_ena;
wire if_req_valid;
wire if_req_op;
wire inst_data_ok;
wire inst_addr_ok;
wire [`REG_BUS] inst_data;

if_stage If_stage(
  	.clk(clk),
  	.rst(rst),
	.new_pc(new_pc),
	.stall(pc_stall),
  
	.inst_data_ok(inst_data_ok),
	.inst_addr_ok(inst_addr_ok),
	.inst_data(inst_data),

	.pc_minus_4(pc_minus_4),
	.if_req_valid(if_req_valid),
	.if_req_op(if_req_op),
  	.inst_addr(inst_addr),
	.inst(if_inst),
	.inst_valid(if_inst_valid),
	.stall_req(if_stall_req)
);

cache ICache(
	.clk(clk),
	.rst(rst),
`ifdef DEBUG
	.pc(),
`endif
	
	.req_valid(if_req_valid),
	.req_op(if_req_op),
	.index(inst_addr[`INDEX_BITSEL]),
	.tag(inst_addr[`TAG_BITSEL]),
	.offset(inst_addr[`OFFSET_BITSEL]),
	.wstrb(8'b1111_1111),
	.wdata(64'b0),
	.addr_ok(inst_addr_ok),
	.data_ok(inst_data_ok),
	.rdata(inst_data),
	.cacheable(1'b1),		//default value

	.raxi_valid(if_valid),
	.raxi_size(if_size),
	.raxi_addr(if_addr),
	.raxi_dvalid(if_dvalid),
	.raxi_dlast(if_dlast),
	.raxi_data(if_data_read),
	
	.waxi_valid(),
	.waxi_size(),
	.waxi_addr(),
	//.waxi_strb(),
	.waxi_data(),
	.waxi_ready(1'b1)
);

/* if_id flip flop */
wire [`INST_BUS] id_inst;
wire id_inst_valid;
wire [`REG_BUS] id_pc;

if_id If_id(
	.clk(clk),
	.rst(rst),
	.if_inst(if_inst),
	.if_inst_valid(if_inst_valid),
	.if_pc(if_pc),
	.stall(if_id_stall),
	
	.id_inst(id_inst),
	.id_inst_valid(id_inst_valid),
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

wire id_exception_flag;
wire [4 : 0] id_exception_cause;
wire [11 : 0] id_csr_addr;


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
	.csr_op(id_csr_op),
	.csr_addr(id_csr_addr),
	.exception_flag(id_exception_flag),
	.exception_cause(id_exception_cause)
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

wire exception_transfer;
wire ex_mem_rena;
wire [4 : 0] ex_rd_waddr;
wire [4 : 0] me_rd_waddr;
//wire control_transfer;
wire ex_csr_rena;
wire me_csr_rena;
wire if_stall_req;
wire exe_stall_req;
wire mem_stall_req;

wire [`REG_BUS] hazard_control_target_pc;
wire [`REG_BUS] hazard_exception_target_pc;

hazard_unit Hazard_unit(
	.rst(rst),
	.clk(clk),
	.ex_mem_rena(ex_mem_rena),
	.ex_rd_waddr(ex_rd_waddr),
	.me_rd_waddr(me_rd_waddr),
	.ex_csr_rena(ex_csr_rena),
	.me_csr_rena(me_csr_rena),
	.id_rs1_rena(id_rs1_rena),	
	.id_rs1_addr(id_rs1_raddr),
	.id_rs2_rena(id_rs2_rena),
	.id_rs2_addr(id_rs2_raddr),
	.branch(me_branch),
	.jump(me_jump),
	.b_flag(me_b_flag),
	.exception_transfer_i(exception_transfer),
	.control_target_pc_i(me_target_pc),
	.exception_target_pc_i(exception_target_pc),
	.if_stall_req(if_stall_req),
	.exe_stall_req(exe_stall_req),
	.mem_stall_req(mem_stall_req),
	
	.control_transfer_o(hazard_control_transfer),
	.exception_transfer_o(hazard_exception_transfer),
	.control_target_pc_o(hazard_control_target_pc),
	.exception_target_pc_o(hazard_exception_target_pc),

	.pc_stall(pc_stall),
	.if_id_stall(if_id_stall),
	.id_ex_stall(id_ex_stall),
	.ex_me_stall(ex_me_stall),
	.me_wb_stall(me_wb_stall)
);
	

/* id_ex flip flop */
wire [`REG_BUS] ex_pc;
wire [`INST_BUS] ex_inst;
wire ex_inst_valid;
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
wire [11 : 0] ex_csr_addr;
wire ex_rs1_sign;
wire ex_rs2_sign;

wire ex_exception_flag;
wire ex_exception_flag_int;
wire [4 : 0] ex_exception_cause;
wire [4 : 0] ex_exception_cause_int;

id_ex Id_ex(
	.clk(clk),
	.rst(rst),
	.stall(id_ex_stall),
	
	.id_pc(id_pc),
	.id_inst(id_inst),
	.id_inst_valid(id_inst_valid),
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
	.id_csr_addr(id_csr_addr),
	.id_rs1_sign(id_rs1_sign),
	.id_rs2_sign(id_rs2_sign),
	.id_exception_flag(id_exception_flag),
	.id_exception_cause(id_exception_cause),

	.ex_pc(ex_pc),
	.ex_inst(ex_inst),
	.ex_inst_valid(ex_inst_valid),
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
	.ex_csr_addr(ex_csr_addr),
	.ex_rs1_sign(ex_rs1_sign),
	.ex_rs2_sign(ex_rs2_sign),
	.ex_exception_flag(ex_exception_flag),
	.ex_exception_cause(ex_exception_cause)
);

/* exe stage */
// mem_stage -> exe_stage
wire [`REG_BUS] me_alu_result;

// exe_stage -> mem stage
wire ex_b_flag;
wire [`REG_BUS] ex_new_rs1_data;	//for mul and div
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
	.clk(clk),
	.rst(rst),
  	.alu_op(ex_alu_op),
	.pc_src(ex_pc_src),
	.pc(ex_pc),
	.alu_op1_src(ex_alu_op1_src),
	.alu_op2_src(ex_alu_op2_src),
	.imm(ex_imm),
	.stall_req_i(exe_stall_req_lsu),
	.stall(id_ex_stall),
	
	.rs1_src(rs1_src),
	.rs2_src(rs2_src),
	.ex_rs1_data(ex_rs1_data),
	.ex_rs2_data(ex_rs2_data),
	.me_alu_result(me_alu_result),
	.wb_rd_data(wb_rd_data),
	
	.inst(ex_inst),

	.uart_valid(uart_valid),
	.uart_ch(uart_ch),

	.mul_result(mul_result),
	//.mul_ready(mul_ready),
	//.mul_valid(mul_valid),
	.div_result(div_result),
	.div_ready(div_ready),
	.div_valid(div_valid),
	.div_32(div_32),

	.stall_req_o(exe_stall_req),
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
`ifdef RISCV_M

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

`else 
assign mul_result = {`ZERO_WORD, `ZERO_WORD};
assign div_result = {`ZERO_WORD, `ZERO_WORD};
assign div_ready = 1'b1;

`endif

/* interrupt */
wire time_int;
wire soft_int;
int_detect Int_detect(
	.ex_exception_flag_i(ex_exception_flag),
	.ex_exception_flag_o(ex_exception_flag_int),

	.inst_valid(ex_inst_valid),
	.time_int(time_int),
	.soft_int(soft_int),
	
	.ex_exception_cause_i(ex_exception_cause),
	.ex_exception_cause_o(ex_exception_cause_int)
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
//wire [`REG_BUS] me_new_rs1_data;
wire [`REG_BUS] me_new_rs2_data;
wire [`REG_BUS] me_pc;
wire [`INST_BUS] me_inst;
wire me_inst_valid;
//wire me_csr_rena;
wire me_csr_wena;
wire [1 : 0] me_csr_op;
wire [11 : 0] me_csr_addr;
wire me_exception_flag;
wire [4 : 0] me_exception_cause;

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
	//.ex_new_rs1_data(ex_new_rs1_data),
	.ex_new_rs2_data(ex_new_rs2_data),
	.ex_rd_wena(ex_rd_wena),
	.ex_rd_waddr(ex_rd_waddr),
	.ex_pc(ex_pc),
	.ex_inst(ex_inst),
	.ex_inst_valid(ex_inst_valid),
	.ex_csr_rena(ex_csr_rena),
	.ex_csr_wena(ex_csr_wena),
	.ex_csr_op(ex_csr_op),
	.ex_csr_addr(ex_csr_addr),
	.ex_exception_flag(ex_exception_flag_int),
	.ex_exception_cause(ex_exception_cause_int),
	
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
	//.me_new_rs1_data(me_new_rs1_data),
	.me_new_rs2_data(me_new_rs2_data),
	.me_rd_wena(me_rd_wena),
	.me_rd_waddr(me_rd_waddr),
	.me_pc(me_pc),
	.me_inst(me_inst),
	.me_inst_valid(me_inst_valid),
	.me_csr_rena(me_csr_rena),
	.me_csr_wena(me_csr_wena),
	.me_csr_op(me_csr_op),
	.me_csr_addr(me_csr_addr),
	.me_exception_flag(me_exception_flag),
	.me_exception_cause(me_exception_cause)

);

wire [`REG_BUS] exception_target_pc;
wire hazard_control_transfer;
wire hazard_exception_transfer;
/* mem stage */
pc_mux Pc_mux(
	.old_pc(pc_minus_4),	
	.control_transfer(hazard_control_transfer),
	.control_target_pc(hazard_control_target_pc),
	.exception_transfer(hazard_exception_transfer),
	.exception_target_pc(hazard_exception_target_pc),
	
	.new_pc(new_pc)
);


// Access memory
wire [`REG_BUS] me_mem_rdata;
wire mem_addr_ok;
wire mem_data_ok;
wire mem_req_valid;
wire mem_req_op;
wire [`REG_BUS] mem_addr;
wire [7 : 0] mem_wstrb;
wire [`REG_BUS] mem_wdata;
wire exe_stall_req_lsu;
wire lsu_cacheable;
lsu Lsu(
	.clk(clk),
	.rst(rst),
	.ex_stall(id_ex_stall),
	.me_stall(ex_me_stall),

	.ex_wstrb(ex_mem_byte_enable),
	.ex_alu_result(ex_alu_result),
	.ex_mem_wdata(ex_new_rs2_data),
	.me_control_transfer(hazard_control_transfer),
	.ex_exception_flag(ex_exception_flag_int),
	.me_exception_flag(me_exception_flag),
	.wb_exception_flag(wb_exception_flag),

	.ex_mem_rena(ex_mem_rena),
	.ex_mem_wena(ex_mem_wena),
	.addr_ok(mem_addr_ok),
	.data_ok(mem_data_ok),
	.mem_data_read_i(me_mem_data_read),
	.cacheable(lsu_cacheable),
	
	.ex_stall_req(exe_stall_req_lsu),
	.me_stall_req(mem_stall_req),
	.me_req_valid(mem_req_valid),
	.me_req_op(mem_req_op),
	.me_addr(mem_addr),
	.me_wstrb(mem_wstrb),
	.me_wdata(mem_wdata),
	.mem_data_read_o(me_mem_rdata)
);
	
wire [`REG_BUS] me_mem_data_read;
cache DCache(
	.clk(clk),
	.rst(rst),
`ifdef DEBUG
	.pc(ex_pc),
`endif
	
	.req_valid(mem_req_valid),
	.req_op(mem_req_op),
	.index(mem_addr[`INDEX_BITSEL]),
	.tag(mem_addr[`TAG_BITSEL]),
	.offset(mem_addr[`OFFSET_BITSEL]),
	.wstrb(mem_wstrb),
	.wdata(mem_wdata),
	.addr_ok(mem_addr_ok),
	.data_ok(mem_data_ok),
	.rdata(me_mem_data_read),
	.cacheable(lsu_cacheable),
	
	.raxi_valid(mem_rvalid),
	.raxi_size(mem_rsize),
	.raxi_addr(mem_raddr),
	.raxi_dvalid(mem_dvalid),
	.raxi_dlast(mem_dlast),
	.raxi_data(mem_data_read),
	
	.waxi_valid(mem_wvalid),
	.waxi_size(mem_wsize),
	.waxi_addr(mem_waddr),
	.waxi_data(mem_data_write),
	.waxi_ready(mem_wready)
);
/*
		me_stage Me_stage(
			.mem_rready(mem_rready),
			.mem_wready(mem_wready),
			.me_mem_wena(me_mem_wena),
			.me_mem_rena(me_mem_rena),
			.mem_byte_enable(me_mem_byte_enable),
			.mem_rresp(mem_rresp),
			.mem_wresp(mem_wresp),
			.mem_data_read_i(mem_data_read),
			.me_alu_result(me_alu_result),
			.me_new_rs2_data(me_new_rs2_data),

			//disable mem_valid signal
			.me_exception_flag(me_exception_flag),
			.wb_exception_flag(wb_exception_flag),
			
			
			.mem_rvalid(mem_rvalid),
			.mem_wvalid(mem_wvalid),
			.mem_data_write(mem_data_write),
			.mem_data_raddr(mem_raddr),
			.mem_data_waddr(mem_waddr),
			.mem_data_read_o(me_mem_rdata),
			.mem_rsize(mem_rsize),
			.mem_wsize(mem_wsize),
			.stall_req(mem_stall_req)
		);
*/

/* me_wb flip flop */
wire [`REG_BUS] wb_alu_result;	
wire [`REG_BUS] wb_mem_data;
wire wb_mem_to_reg;
wire wb_mem_ext_un;
wire [7 : 0] wb_mem_byte_enable;
wire [`REG_BUS] wb_pc;
wire [`INST_BUS] wb_inst;
wire wb_inst_valid;
wire wb_csr_rena;
wire wb_csr_wena;
wire [1 : 0] wb_csr_op;
wire [11 : 0] wb_csr_addr;
wire wb_rd_wena_normal;
//wire [`REG_BUS] wb_new_rs1_data;
wire wb_exception_flag;
wire [4 : 0] wb_exception_cause;

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
	.me_inst_valid(me_inst_valid),
	.me_csr_rena(me_csr_rena),
	.me_csr_wena(me_csr_wena),
	.me_csr_op(me_csr_op),
	.me_csr_addr(me_csr_addr),
	//.me_new_rs1_data(me_new_rs1_data),
	.me_exception_flag(me_exception_flag),
	.me_exception_cause(me_exception_cause),
	
	.wb_alu_result(wb_alu_result),
	.wb_mem_data(wb_mem_data),
	.wb_mem_to_reg(wb_mem_to_reg),
	.wb_mem_ext_un(wb_mem_ext_un),
	.wb_mem_byte_enable(wb_mem_byte_enable),
	.wb_rd_wena(wb_rd_wena_normal),		//before exception
	.wb_rd_waddr(wb_rd_waddr),
	.wb_pc(wb_pc),
	.wb_inst(wb_inst),
	.wb_inst_valid(wb_inst_valid),
	.wb_csr_rena(wb_csr_rena),
	.wb_csr_wena(wb_csr_wena),
	.wb_csr_op(wb_csr_op),
	.wb_csr_addr(wb_csr_addr),
	//.wb_new_rs1_data(wb_new_rs1_data),
	.wb_exception_flag(wb_exception_flag),
	.wb_exception_cause(wb_exception_cause)
);

/* wb stage */
assign diff_wb_rd_wena = wb_rd_wena;
assign diff_wb_rd_waddr = wb_rd_waddr;
assign diff_wb_rd_data = wb_rd_data;
assign diff_wb_pc = wb_pc;
assign diff_wb_inst = wb_inst;
assign diff_wb_inst_valid = wb_inst_valid & (me_wb_stall != `STALL_KEEP) & ~(wb_exception_flag & wb_exception_cause[4]);

wire [63 : 0] csr_data;
rd_wmux Rd_wmux(
	.alu_result(wb_alu_result),
	.mem_data(wb_mem_data),
	.csr_data(csr_data),
	.mem_to_reg(wb_mem_to_reg),
	.mem_ext_un(wb_mem_ext_un),
	.byte_enable(wb_mem_byte_enable),
	.csr_rena(wb_csr_rena),
	.rd_wena_i(wb_rd_wena_normal),
	//disable rd_wena signal
	.exception_flag(wb_exception_flag),
	
	.rd_wdata(wb_rd_data),
	.rd_wena_o(wb_rd_wena)
);

assign interrupt = wb_inst_valid & wb_exception_flag & wb_exception_cause[4];

csr Csr(
	.clk(clk),
	.rst(rst),
	//.csr_addr(wb_alu_result[11 : 0]),
	.csr_addr(wb_csr_addr),
	.csr_rena(wb_csr_rena),
	.csr_wena(wb_csr_wena),
	.csr_op(wb_csr_op),
	.csr_wdata(wb_alu_result),
	//.rs1_data(wb_new_rs1_data),
	.time_irq(time_irq),
	.soft_irq(sip),

	.time_int(time_int),
	.soft_int(soft_int),

	.exception_flag(wb_exception_flag),
	.exception_cause(wb_exception_cause),
	.epc(wb_pc),

	.csr_data(csr_data),
	.exception_transfer(exception_transfer),
	.exception_target_pc(exception_target_pc),

	//difftest
	.diff_mscratch(diff_mscratch),
	.diff_mstatus(diff_mstatus),
	.diff_sstatus(diff_sstatus),
	.diff_mcause(diff_mcause),
	.diff_mepc(diff_mepc),
	.diff_mtvec(diff_mtvec),
	.diff_mip(diff_mip),
	.diff_mie(diff_mie)
);



endmodule
