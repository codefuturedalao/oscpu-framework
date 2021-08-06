//--jacksonsang--
`include "defines.v"

module SimTop(
    input         clock,
    input         reset,

    input  [63:0] io_logCtrl_log_begin,
    input  [63:0] io_logCtrl_log_end,
    input  [63:0] io_logCtrl_log_level,
    input         io_perfInfo_clean,
    input         io_perfInfo_dump,

    output        io_uart_out_valid,
    output [7:0]  io_uart_out_ch,
    output        io_uart_in_valid,
    input  [7:0]  io_uart_in_ch
);


// hazard_unit
wire [1 : 0] pc_stall;
wire [1 : 0] if_id_stall;
wire [1 : 0] id_ex_stall;
wire [1 : 0] ex_me_stall;
wire [1 : 0] me_wb_stall;

/* if stage */
wire clk = clock;
wire rst = reset;
wire [`REG_BUS] new_pc;
wire [`REG_BUS] if_pc;
wire [`INST_BUS] if_inst;
wire inst_ena;

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
wire [`REG_BUS] regs[0 : 31];


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
	.ex_csr_op(ex_csr_op)
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
//wire wb_rd_wena;
//wire [4 : 0] wb_rd_waddr; 
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

	.new_rs1_data(ex_new_rs1_data),
	.new_rs2_data(ex_new_rs2_data),
	.alu_result(ex_alu_result),
	.target_pc(ex_target_pc),
	.b_flag(ex_b_flag)
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
reg [`REG_BUS] inst_rdata;
wire [`REG_BUS] mem_waddr;
wire [`REG_BUS] mem_raddr;
wire [`REG_BUS] me_mem_rdata;
wire [`REG_BUS] mem_wdata;
wire [`REG_BUS] wmask;

wire [7 : 0] byte_en_new;

// waddr is same as raddr
assign mem_waddr = me_alu_result;
assign mem_raddr = me_alu_result;
wire [5 : 0] shift_bit = me_alu_result[2:0] << 3;
assign mem_wdata = me_new_rs2_data << shift_bit;

assign byte_en_new = me_mem_byte_enable << me_alu_result[2:0];

assign wmask = { {8{byte_en_new[7]}},
                {8{byte_en_new[6]}},
                {8{byte_en_new[5]}},
                {8{byte_en_new[4]}},
                {8{byte_en_new[3]}},
                {8{byte_en_new[2]}},
                {8{byte_en_new[1]}},
                {8{byte_en_new[0]}}};

MyRAMHelper RAMHelper(
  .clk              (clock),
  .inst_en               (inst_ena),
  .inst_rIdx             ((if_pc - `PC_START) >> 3),
  .inst_rdata            (inst_rdata),
  .data_en               (me_mem_rena),
  .data_rIdx             ((mem_raddr - `PC_START) >> 3),
  .data_rdata            (me_mem_rdata),
  .wIdx             ((mem_waddr - `PC_START) >> 3),
  .wdata            (mem_wdata),
  .wmask            (wmask),
  .wen              (me_mem_wena)
);
assign if_inst = if_pc[2] ? inst_rdata[63 : 32] : inst_rdata[31 : 0];

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

// Difftest
reg cmt_wen;
reg [7:0] cmt_wdest;
reg [`REG_BUS] cmt_wdata;
reg [`REG_BUS] cmt_pc;
reg [31:0] cmt_inst;
reg vaild;
reg skip;
reg [63:0] cycleCnt;
reg [63:0] instrCnt;

always @(posedge clock) begin
  if (reset) begin
    {cmt_wen, cmt_wdest, cmt_wdata, cmt_pc, cmt_inst, vaild, cycleCnt, instrCnt} <= 0;
  end
  else begin
    cmt_wen <= wb_rd_wena;	
    cmt_wdest <= {3'd0, wb_rd_waddr};
    cmt_wdata <= wb_rd_data;
    cmt_pc <= wb_pc;		//TODO:
    cmt_inst <= wb_inst;
    vaild <= (wb_pc == `ZERO_WORD | wb_pc == 64'h0000000080000bf0) ? 1'b0 : 1'b1;

    // Skip comparison of the first instruction
    // Because the result required to commit cannot be calculated in time before first InstrCommit during verilator simulation
    // Maybe you can avoid it in pipeline
    //skip <= (wb_pc == `PC_START) || (wb_pc == `ZERO_WORD);
    skip <= (wb_pc == `PC_START);
    
    cycleCnt <= 1 + cycleCnt;
    instrCnt <= 1 + instrCnt;
  end
end

DifftestInstrCommit DifftestInstrCommit(
  .clock              (clock),
  .coreid             (0),
  .index              (0),
  .valid              (vaild),
  .pc                 (cmt_pc),
  .instr              (cmt_inst),
  .skip               (skip),
  .isRVC              (0),
  .scFailed           (0),
  .wen                (cmt_wen),
  .wdest              (cmt_wdest),
  .wdata              (cmt_wdata)
);

DifftestArchIntRegState DifftestArchIntRegState (
  .clock              (clock),
  .coreid             (0),
  .gpr_0              (regs[0]),
  .gpr_1              (regs[1]),
  .gpr_2              (regs[2]),
  .gpr_3              (regs[3]),
  .gpr_4              (regs[4]),
  .gpr_5              (regs[5]),
  .gpr_6              (regs[6]),
  .gpr_7              (regs[7]),
  .gpr_8              (regs[8]),
  .gpr_9              (regs[9]),
  .gpr_10             (regs[10]),
  .gpr_11             (regs[11]),
  .gpr_12             (regs[12]),
  .gpr_13             (regs[13]),
  .gpr_14             (regs[14]),
  .gpr_15             (regs[15]),
  .gpr_16             (regs[16]),
  .gpr_17             (regs[17]),
  .gpr_18             (regs[18]),
  .gpr_19             (regs[19]),
  .gpr_20             (regs[20]),
  .gpr_21             (regs[21]),
  .gpr_22             (regs[22]),
  .gpr_23             (regs[23]),
  .gpr_24             (regs[24]),
  .gpr_25             (regs[25]),
  .gpr_26             (regs[26]),
  .gpr_27             (regs[27]),
  .gpr_28             (regs[28]),
  .gpr_29             (regs[29]),
  .gpr_30             (regs[30]),
  .gpr_31             (regs[31])
);

DifftestTrapEvent DifftestTrapEvent(
  .clock              (clock),
  .coreid             (0),
  .valid              (wb_inst[6:0] == 7'h6b),	
  .code               (regs[10][7:0]),
  .pc                 (cmt_pc),
  .cycleCnt           (cycleCnt),
  .instrCnt           (instrCnt)
);

DifftestCSRState DifftestCSRState(
  .clock              (clock),
  .coreid             (0),
  .priviledgeMode     (0),
  .mstatus            (0),
  .sstatus            (0),
  .mepc               (0),
  .sepc               (0),
  .mtval              (0),
  .stval              (0),
  .mtvec              (0),
  .stvec              (0),
  .mcause             (0),
  .scause             (0),
  .satp               (0),
  .mip                (0),
  .mie                (0),
  .mscratch           (0),
  .sscratch           (0),
  .mideleg            (0),
  .medeleg            (0)
);

DifftestArchFpRegState DifftestArchFpRegState(
  .clock              (clock),
  .coreid             (0),
  .fpr_0              (0),
  .fpr_1              (0),
  .fpr_2              (0),
  .fpr_3              (0),
  .fpr_4              (0),
  .fpr_5              (0),
  .fpr_6              (0),
  .fpr_7              (0),
  .fpr_8              (0),
  .fpr_9              (0),
  .fpr_10             (0),
  .fpr_11             (0),
  .fpr_12             (0),
  .fpr_13             (0),
  .fpr_14             (0),
  .fpr_15             (0),
  .fpr_16             (0),
  .fpr_17             (0),
  .fpr_18             (0),
  .fpr_19             (0),
  .fpr_20             (0),
  .fpr_21             (0),
  .fpr_22             (0),
  .fpr_23             (0),
  .fpr_24             (0),
  .fpr_25             (0),
  .fpr_26             (0),
  .fpr_27             (0),
  .fpr_28             (0),
  .fpr_29             (0),
  .fpr_30             (0),
  .fpr_31             (0)
);

endmodule
