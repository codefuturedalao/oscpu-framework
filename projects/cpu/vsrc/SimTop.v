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

// if_stage
wire [63 : 0] pc;
wire [63 : 0] new_pc;
wire [63 : 0] b_offset;
wire [`REG_BUS] j_offset;
wire [31 : 0] inst;
wire inst_ena;

wire clk = clock;
wire rst = reset;

/* if stage */
if_stage If_stage(
  .clk(clk),
  .rst(rst),
	.new_pc(new_pc),
  
  .inst_addr(pc),
  .inst_ena(inst_ena)
);


pc_mux Pc_mux(
	.old_pc(pc),
	.branch(branch),
	.b_flag(b_flag),
	.b_offset(b_offset),
	.jump(jump),
	.j_offset(j_offset),
	.rs1_data(r_data1),
	
	.new_pc(new_pc)
);
	

// id_stage
// id_stage -> regfile
wire rs1_r_ena;
wire [4 : 0]rs1_r_addr;
wire rs2_r_ena;
wire [4 : 0]rs2_r_addr;
wire rd_w_ena;
wire [4 : 0]rd_w_addr;
// id_stage -> exe_stage
wire [`ALU_OP_BUS] alu_op;
wire [`REG_BUS]op1;
wire [`REG_BUS]op2;
wire branch;
wire [1:0] jump;
// id_stage -> mem_stage
wire mem_r_ena;
wire mem_w_ena;
wire mem_to_reg;
wire mem_ext_un;
wire [7 : 0] byte_enable;

wire [`REG_BUS]rd_data;

// regfile -> id_stage
wire [`REG_BUS] r_data1;
wire [`REG_BUS] r_data2;
// regfile -> difftest
wire [`REG_BUS] regs[0 : 31];

/* id stage */
regfile Regfile(
  .clk(clk),
  .rst(rst),
  .w_addr(rd_w_addr),
  .w_data(rd_data),
  .w_ena(rd_w_ena),
  
  .r_addr1(rs1_r_addr),
  .r_data1(r_data1),
  .r_ena1(rs1_r_ena),
  .r_addr2(rs2_r_addr),
  .r_data2(r_data2),
  .r_ena2(rs2_r_ena),

  .regs_o(regs)
);

rd_wmux Rd_wmux(
	.alu_result(alu_result),
	.mem_data(mem_rdata),
	.mem_to_reg(mem_to_reg),
	.mem_ext_un(mem_ext_un),
	.byte_enable(byte_enable),
	
	.rd_wdata(rd_data)
);


id_stage Id_stage(
  .rst(rst),
  .inst(inst),
  .pc(pc),
  .rs1_data(r_data1),
  .rs2_data(r_data2),
  
  .rs1_r_ena(rs1_r_ena),
  .rs1_r_addr(rs1_r_addr),
  .rs2_r_ena(rs2_r_ena),
  .rs2_r_addr(rs2_r_addr),
  .rd_w_ena(rd_w_ena),
  .rd_w_addr(rd_w_addr),
  .alu_op(alu_op),
  .op1(op1),
  .op2(op2),
	.branch(branch),
	.b_offset(b_offset),
	.jump(jump),
	.j_offset(j_offset),
	.mem_r_ena(mem_r_ena),
	.mem_w_ena(mem_w_ena),
	.mem_to_reg(mem_to_reg),
	.byte_enable(byte_enable),
	.mem_ext_un(mem_ext_un)
	
);

// exe_stage
// exe_stage -> other stage
wire [4 : 0]inst_type_o;
wire b_flag;
// exe_stage -> regfile
wire [`REG_BUS]alu_result;

/* exe stage */
exe_stage Exe_stage(
  .rst(rst),
  .alu_op(alu_op),
  .op1(op1),
  .op2(op2),
  
  .rd_data(alu_result),
	.b_flag(b_flag)
);


// Access memory
reg [63:0] inst_rdata;
wire [`REG_BUS] mem_raddr;
wire [`REG_BUS] mem_rdata;
wire [`REG_BUS] mem_waddr;
wire [`REG_BUS] mem_wdata;
wire [`REG_BUS] wmask;

wire [7 : 0] byte_en_new;

// waddr is same as raddr
assign mem_waddr = alu_result;
assign mem_raddr = alu_result;
wire [5 : 0] shift_bit = alu_result[2:0] << 3;
assign mem_wdata = r_data2 << shift_bit;

assign byte_en_new = byte_enable << alu_result[2:0];

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
  .inst_rIdx             ((pc - `PC_START) >> 3),
  .inst_rdata            (inst_rdata),
  .data_en               (mem_r_ena),
  .data_rIdx             ((mem_raddr - `PC_START) >> 3),
  .data_rdata            (mem_rdata),
  .wIdx             ((mem_waddr - `PC_START) >> 3),
  .wdata            (mem_wdata),
  .wmask            (wmask),
  .wen              (mem_w_ena)
);
assign inst = pc[2] ? inst_rdata[63 : 32] : inst_rdata[31 : 0];
//assign mem_data = [2] ? mem_rdata[63 : 32] : mem_rdata[31 : 0];


// Difftest
reg cmt_wen;
reg [7:0]cmt_wdest;
reg [`REG_BUS] cmt_wdata;
reg [`REG_BUS] cmt_pc;
reg [31:0]cmt_inst;
reg vaild;
reg skip;
reg [63:0] cycleCnt;
reg [63:0] instrCnt;

always @(posedge clock) begin
  if (reset) begin
    {cmt_wen, cmt_wdest, cmt_wdata, cmt_pc, cmt_inst, vaild, cycleCnt, instrCnt} = 0;
  end
  else begin
    cmt_wen = rd_w_ena;
    cmt_wdest = {3'd0, rd_w_addr};
    cmt_wdata = rd_data;
    cmt_pc = pc;
    cmt_inst = inst;
    vaild = 1'd1;

    // Skip comparison of the first instruction
    // Because the result required to commit cannot be calculated in time before first InstrCommit during verilator simulation
    // Maybe you can avoid it in pipeline
    skip = pc == `PC_START;
    
    cycleCnt += 1;
    instrCnt += 1;
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
  .valid              (inst[6:0] == 7'h6b),
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
