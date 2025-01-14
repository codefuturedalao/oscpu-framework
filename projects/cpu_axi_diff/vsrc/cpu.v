
//--xuezhen--

`include "defines.v"

module cpu(
    input                               clock,
    input                               reset,
    
    output                              if_valid,
    input                               if_ready,
    input  [63:0]                       if_data_read,
    output [63:0]                       if_addr,
    output [1:0]                        if_size,
    input  [1:0]                        if_resp
);

// if_stage
wire [63 : 0] pc;
wire [31 : 0] inst;

// id_stage
// id_stage -> regfile
wire rs1_r_ena;
wire [4 : 0]rs1_r_addr;
wire rs2_r_ena;
wire [4 : 0]rs2_r_addr;
wire rd_w_ena;
wire [4 : 0]rd_w_addr;
// id_stage -> exe_stage
wire [4 : 0]inst_type;
wire [7 : 0]inst_opcode;
wire [`REG_BUS]op1;
wire [`REG_BUS]op2;

// regfile -> id_stage
wire [`REG_BUS] r_data1;
wire [`REG_BUS] r_data2;
// regfile -> difftest
wire [`REG_BUS] regs[0 : 31];

// exe_stage
// exe_stage -> other stage
wire [4 : 0]inst_type_o;
// exe_stage -> regfile
wire [`REG_BUS]rd_data;


wire fetched;

if_stage If_stage(
  .clk                (clock),
  .rst                (reset),
  
  .pc                 (pc),
  .inst               (inst),

  .if_valid           (if_valid),
  .if_ready           (if_ready),
  .if_data_read       (if_data_read),
  .if_addr            (if_addr),
  .if_size            (if_size),
  .if_resp            (if_resp),

  .fetched            (fetched)
);

id_stage Id_stage(
  .rst                (reset),
  .inst               (inst),
  .rs1_data           (r_data1),
  .rs2_data           (r_data2),
  
  .rs1_r_ena          (rs1_r_ena),
  .rs1_r_addr         (rs1_r_addr),
  .rs2_r_ena          (rs2_r_ena),
  .rs2_r_addr         (rs2_r_addr),
  .rd_w_ena           (rd_w_ena),
  .rd_w_addr          (rd_w_addr),
  .inst_type          (inst_type),
  .inst_opcode        (inst_opcode),
  .op1                (op1),
  .op2                (op2)
);

exe_stage Exe_stage(
  .rst                (reset),
  .inst_type_i        (inst_type),
  .inst_opcode        (inst_opcode),
  .op1                (op1),
  .op2                (op2),
  
  .inst_type_o        (inst_type_o),
  .rd_data            (rd_data)
);

regfile Regfile(
  .clk                (clock),
  .rst                (reset),
  .w_addr             (rd_w_addr),
  .w_data             (rd_data),
  .w_ena              (rd_w_ena),
  
  .r_addr1            (rs1_r_addr),
  .r_data1            (r_data1),
  .r_ena1             (rs1_r_ena),
  .r_addr2            (rs2_r_addr),
  .r_data2            (r_data2),
  .r_ena2             (rs2_r_ena),

  .regs_o             (regs)
);


// Difftest
reg cmt_wen;
reg [7:0] cmt_wdest;
reg [`REG_BUS] cmt_wdata;
reg [`REG_BUS] cmt_pc;
reg [31:0] cmt_inst;
reg cmt_valid;
reg trap;
reg [7:0] trap_code;
reg [63:0] cycleCnt;
reg [63:0] instrCnt;
reg [`REG_BUS] regs_diff [0 : 31];

wire inst_valid = fetched;

always @(negedge clock) begin
  if (reset) begin
    {cmt_wen, cmt_wdest, cmt_wdata, cmt_pc, cmt_inst, cmt_valid, trap, trap_code, cycleCnt, instrCnt} <= 0;
  end
  else if (~trap) begin
    cmt_wen <= rd_w_ena;
    cmt_wdest <= {3'd0, rd_w_addr};
    cmt_wdata <= rd_data;
    cmt_pc <= pc;
    cmt_inst <= inst;
    cmt_valid <= inst_valid;

    regs_diff <= regs;

    trap <= inst[6:0] == 7'h6b;
    trap_code <= regs[10][7:0];
    cycleCnt <= cycleCnt + 1;
    instrCnt <= instrCnt + inst_valid;
  end
end

DifftestInstrCommit DifftestInstrCommit(
  .clock              (clock),
  .coreid             (0),
  .index              (0),
  .valid              (cmt_valid),
  .pc                 (cmt_pc),
  .instr              (cmt_inst),
  .skip               (0),
  .isRVC              (0),
  .scFailed           (0),
  .wen                (cmt_wen),
  .wdest              (cmt_wdest),
  .wdata              (cmt_wdata)
);

DifftestArchIntRegState DifftestArchIntRegState (
  .clock              (clock),
  .coreid             (0),
  .gpr_0              (regs_diff[0]),
  .gpr_1              (regs_diff[1]),
  .gpr_2              (regs_diff[2]),
  .gpr_3              (regs_diff[3]),
  .gpr_4              (regs_diff[4]),
  .gpr_5              (regs_diff[5]),
  .gpr_6              (regs_diff[6]),
  .gpr_7              (regs_diff[7]),
  .gpr_8              (regs_diff[8]),
  .gpr_9              (regs_diff[9]),
  .gpr_10             (regs_diff[10]),
  .gpr_11             (regs_diff[11]),
  .gpr_12             (regs_diff[12]),
  .gpr_13             (regs_diff[13]),
  .gpr_14             (regs_diff[14]),
  .gpr_15             (regs_diff[15]),
  .gpr_16             (regs_diff[16]),
  .gpr_17             (regs_diff[17]),
  .gpr_18             (regs_diff[18]),
  .gpr_19             (regs_diff[19]),
  .gpr_20             (regs_diff[20]),
  .gpr_21             (regs_diff[21]),
  .gpr_22             (regs_diff[22]),
  .gpr_23             (regs_diff[23]),
  .gpr_24             (regs_diff[24]),
  .gpr_25             (regs_diff[25]),
  .gpr_26             (regs_diff[26]),
  .gpr_27             (regs_diff[27]),
  .gpr_28             (regs_diff[28]),
  .gpr_29             (regs_diff[29]),
  .gpr_30             (regs_diff[30]),
  .gpr_31             (regs_diff[31])
);

DifftestTrapEvent DifftestTrapEvent(
  .clock              (clock),
  .coreid             (0),
  .valid              (trap),
  .code               (trap_code),
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
