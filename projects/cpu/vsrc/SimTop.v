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

wire [`REG_BUS] inst_rdata;
wire [`REG_BUS] inst_addr;
wire inst_ena;
wire [`REG_BUS] mem_rdata;
wire [`REG_BUS] mem_raddr;
wire mem_rena;
wire [`REG_BUS] mem_wdata;
wire [`REG_BUS] mem_waddr;
wire [`REG_BUS] mem_wmask;
wire mem_wena;


wire wb_rd_wena;
wire [4 : 0] wb_rd_waddr;
wire [`REG_BUS] wb_rd_data;
wire [`REG_BUS] wb_pc;
wire [`REG_BUS] wb_inst;
wire [`REG_BUS] regs[0 : 31];

rvcpu Rvcpu(
	.clk(clock),
	.rst(reset),
	.inst_rdata(inst_rdata),
	.inst_addr(inst_addr),
	.inst_ena(inst_ena),

	.mem_rdata(mem_rdata),
	.mem_raddr(mem_raddr),
	.mem_rena(mem_rena),
	
	.mem_wdata(mem_wdata),
	.mem_waddr(mem_waddr),
	.mem_wmask(mem_wmask),
	.mem_wena(mem_wena),

	//difftest
	.diff_wb_rd_wena(wb_rd_wena),
	.diff_wb_rd_waddr(wb_rd_waddr),
	.diff_wb_rd_data(wb_rd_data),
	.diff_wb_pc(wb_pc),
	.diff_wb_inst(wb_inst),
	.regs(regs)
	
	
);


MyRAMHelper RAMHelper(
  .clk              (clock),
  .inst_en               (inst_ena),
  .inst_rIdx             ((inst_addr - `PC_START) >> 3),
  .inst_rdata            (inst_rdata),
  .data_en               (mem_rena),
  .data_rIdx             ((mem_raddr - `PC_START) >> 3),
  .data_rdata            (mem_rdata),
  .wIdx             ((mem_waddr - `PC_START) >> 3),
  .wdata            (mem_wdata),
  .wmask            (mem_wmask),
  .wen              (mem_wena)
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
    cmt_pc <= wb_pc;		
    cmt_inst <= wb_inst;
   // vaild <= (wb_pc == `ZERO_WORD | wb_pc == 64'h0000000080000bf0) ? 1'b0 : 1'b1;
    vaild <= (wb_pc == `ZERO_WORD) ? 1'b0 : 1'b1;

    // Skip comparison of the first instruction
    // Because the result required to commit cannot be calculated in time before first InstrCommit during verilator simulation
    // Maybe you can avoid it in pipeline
    //skip <= (wb_pc == `PC_START) || (wb_pc == `ZERO_WORD);
    //skip <= (wb_pc == `PC_START| wb_pc == 64'h0000000080000c1c | wb_pc == 64'h0000000080000c24);
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
