//--jacksonsang--
`include "defines.v"
`define AXI_TOP_INTERFACE(name) io_memAXI_0_``name

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
    input  [7:0]  io_uart_in_ch,

	//Axi4 port	
    input                               `AXI_TOP_INTERFACE(aw_ready),
    output                              `AXI_TOP_INTERFACE(aw_valid),
    output [`AXI_ADDR_WIDTH-1:0]        `AXI_TOP_INTERFACE(aw_bits_addr),
    output [2:0]                        `AXI_TOP_INTERFACE(aw_bits_prot),
    output [`AXI_ID_WIDTH-1:0]          `AXI_TOP_INTERFACE(aw_bits_id),
    output [`AXI_USER_WIDTH-1:0]        `AXI_TOP_INTERFACE(aw_bits_user),
    output [7:0]                        `AXI_TOP_INTERFACE(aw_bits_len),
    output [2:0]                        `AXI_TOP_INTERFACE(aw_bits_size),
    output [1:0]                        `AXI_TOP_INTERFACE(aw_bits_burst),
    output                              `AXI_TOP_INTERFACE(aw_bits_lock),
    output [3:0]                        `AXI_TOP_INTERFACE(aw_bits_cache),
    output [3:0]                        `AXI_TOP_INTERFACE(aw_bits_qos),
    
    input                               `AXI_TOP_INTERFACE(w_ready),
    output                              `AXI_TOP_INTERFACE(w_valid),
    output [`AXI_DATA_WIDTH-1:0]        `AXI_TOP_INTERFACE(w_bits_data)         [0:0],
    //output [`AXI_DATA_WIDTH-1:0]        `AXI_TOP_INTERFACE(w_bits_data),
    output [`AXI_DATA_WIDTH/8-1:0]      `AXI_TOP_INTERFACE(w_bits_strb),
    output                              `AXI_TOP_INTERFACE(w_bits_last),
    output [`AXI_ID_WIDTH-1:0]          `AXI_TOP_INTERFACE(w_bits_id),
    
    output                              `AXI_TOP_INTERFACE(b_ready),
    input                               `AXI_TOP_INTERFACE(b_valid),
    input  [1:0]                        `AXI_TOP_INTERFACE(b_bits_resp),
    input  [`AXI_ID_WIDTH-1:0]          `AXI_TOP_INTERFACE(b_bits_id),
    input  [`AXI_USER_WIDTH-1:0]        `AXI_TOP_INTERFACE(b_bits_user),

    input                               `AXI_TOP_INTERFACE(ar_ready),
    output                              `AXI_TOP_INTERFACE(ar_valid),
    output [`AXI_ADDR_WIDTH-1:0]        `AXI_TOP_INTERFACE(ar_bits_addr),
    output [2:0]                        `AXI_TOP_INTERFACE(ar_bits_prot),
    output [`AXI_ID_WIDTH-1:0]          `AXI_TOP_INTERFACE(ar_bits_id),
    output [`AXI_USER_WIDTH-1:0]        `AXI_TOP_INTERFACE(ar_bits_user),
    output [7:0]                        `AXI_TOP_INTERFACE(ar_bits_len),
    output [2:0]                        `AXI_TOP_INTERFACE(ar_bits_size),
    output [1:0]                        `AXI_TOP_INTERFACE(ar_bits_burst),
    output                              `AXI_TOP_INTERFACE(ar_bits_lock),
    output [3:0]                        `AXI_TOP_INTERFACE(ar_bits_cache),
    output [3:0]                        `AXI_TOP_INTERFACE(ar_bits_qos),
    
    output                              `AXI_TOP_INTERFACE(r_ready),
    input                               `AXI_TOP_INTERFACE(r_valid),
    input  [1:0]                        `AXI_TOP_INTERFACE(r_bits_resp),
    input  [`AXI_DATA_WIDTH-1:0]        `AXI_TOP_INTERFACE(r_bits_data)         [3:0],
    input                               `AXI_TOP_INTERFACE(r_bits_last),
    input  [`AXI_ID_WIDTH-1:0]          `AXI_TOP_INTERFACE(r_bits_id),
    input  [`AXI_USER_WIDTH-1:0]        `AXI_TOP_INTERFACE(r_bits_user)
);


/* from if stage */
wire if_valid;
wire if_ready;
wire if_req = `REQ_READ;
wire [63:0] if_data_read;
//wire [63:0] data_write;
wire [63:0] if_addr;
wire [1:0] if_size;
wire [1:0] if_resp;

/* from mem stage */
wire mem_rvalid;
wire mem_wvalid;
wire mem_rready;
wire mem_wready;
wire [63:0] mem_data_read;
wire [63:0] mem_data_write;
wire [63:0] mem_raddr;
wire [63:0] mem_waddr;
wire [1:0] mem_rsize;
wire [1:0] mem_wsize;
wire [1:0] mem_rresp;
wire [1:0] mem_wresp;

/* from wb stage */
wire wb_rd_wena;
wire [4 : 0] wb_rd_waddr;
wire [`REG_BUS] wb_rd_data;
wire [`REG_BUS] wb_pc;
wire [`REG_BUS] wb_inst;
wire wb_inst_valid;
wire [`REG_BUS] regs[0 : 31];		//directly from regfile

wire [`MXLEN-1 : 0] mstatus;
wire [`MXLEN-1 : 0] mcause;
wire [`MXLEN-1 : 0] mepc;
wire [`MXLEN-1 : 0] mtvec;

rvcpu Rvcpu(
	.clk(clock),
	.rst(reset),

	.if_ready(if_ready),
	.if_resp(if_resp),
	.if_data_read(if_data_read),
	.if_valid(if_valid),
	.if_addr(if_addr),
	.if_size(if_size),

	.mem_rready(mem_wready),
	.mem_wready(mem_wready),
	.mem_rresp(mem_rresp),
	.mem_wresp(mem_wresp),
	.mem_data_read(mem_data_read),
	.mem_rvalid(mem_rvalid),
	.mem_wvalid(mem_wvalid),
	//.mem_req(mem_req),
	.mem_raddr(mem_raddr),
	.mem_waddr(mem_waddr),
	.mem_data_write(mem_data_write),
	.mem_rsize(mem_rsize),
	.mem_wsize(mem_wsize),

	//difftest
	.diff_wb_rd_wena(wb_rd_wena),
	.diff_wb_rd_waddr(wb_rd_waddr),
	.diff_wb_rd_data(wb_rd_data),
	.diff_wb_pc(wb_pc),
	.diff_wb_inst(wb_inst),
	.diff_wb_inst_valid(wb_inst_valid),
	.regs(regs),
	.diff_mstatus(mstatus),
	.diff_mcause(mcause),
	.diff_mepc(mepc),
	.diff_mtvec(mtvec)
);

    wire aw_ready;
    wire aw_valid;
    wire [`AXI_ADDR_WIDTH-1:0] aw_addr;
    wire [2:0] aw_prot;
    wire [`AXI_ID_WIDTH-1:0] aw_id;
    wire [`AXI_USER_WIDTH-1:0] aw_user;
    wire [7:0] aw_len;
    wire [2:0] aw_size;
    wire [1:0] aw_burst;
    wire aw_lock;
    wire [3:0] aw_cache;
    wire [3:0] aw_qos;

    wire w_ready;
    wire w_valid;
    wire [`AXI_DATA_WIDTH-1:0] w_data [0:0];
    wire [`AXI_DATA_WIDTH/8-1:0] w_strb;
    wire w_last;
    wire [`AXI_ID_WIDTH-1:0] w_id;
    
    wire b_ready;
    wire b_valid;
    wire [1:0] b_resp;
    wire [`AXI_ID_WIDTH-1:0] b_id;
    wire [`AXI_USER_WIDTH-1:0] b_user;

    wire ar_ready;
    wire ar_valid;
    wire [`AXI_ADDR_WIDTH-1:0] ar_addr;
    wire [2:0] ar_prot;
    wire [`AXI_ID_WIDTH-1:0] ar_id;
    wire [`AXI_USER_WIDTH-1:0] ar_user;
    wire [7:0] ar_len;
    wire [2:0] ar_size;
    wire [1:0] ar_burst;
    wire ar_lock;
    wire [3:0] ar_cache;
    wire [3:0] ar_qos;
    
    wire r_ready;
    wire r_valid;
    wire [1:0] r_resp;
    wire [`AXI_DATA_WIDTH-1:0] r_data;
    wire r_last;
    wire [`AXI_ID_WIDTH-1:0] r_id;
    wire [`AXI_USER_WIDTH-1:0] r_user;

    assign aw_ready                                 = `AXI_TOP_INTERFACE(aw_ready);
    assign `AXI_TOP_INTERFACE(aw_valid)             = aw_valid;
    assign `AXI_TOP_INTERFACE(aw_bits_addr)         = aw_addr;
    assign `AXI_TOP_INTERFACE(aw_bits_prot)         = aw_prot;
    assign `AXI_TOP_INTERFACE(aw_bits_id)           = aw_id;
    assign `AXI_TOP_INTERFACE(aw_bits_user)         = aw_user;
    assign `AXI_TOP_INTERFACE(aw_bits_len)          = aw_len;
    assign `AXI_TOP_INTERFACE(aw_bits_size)         = aw_size;
    assign `AXI_TOP_INTERFACE(aw_bits_burst)        = aw_burst;
    assign `AXI_TOP_INTERFACE(aw_bits_lock)         = aw_lock;
    assign `AXI_TOP_INTERFACE(aw_bits_cache)        = aw_cache;
    assign `AXI_TOP_INTERFACE(aw_bits_qos)          = aw_qos;

	assign w_ready 									= `AXI_TOP_INTERFACE(w_ready);
	assign `AXI_TOP_INTERFACE(w_valid)				= w_valid;
	assign `AXI_TOP_INTERFACE(w_bits_data)			= w_data;
	assign `AXI_TOP_INTERFACE(w_bits_strb)			= w_strb;
	assign `AXI_TOP_INTERFACE(w_bits_last)			= w_last;
	assign `AXI_TOP_INTERFACE(w_bits_id)			= w_id;

	assign `AXI_TOP_INTERFACE(b_ready)				= b_ready;
	assign b_valid 									= `AXI_TOP_INTERFACE(b_valid);
	assign b_resp									= `AXI_TOP_INTERFACE(b_bits_resp);
	assign b_id										= `AXI_TOP_INTERFACE(b_bits_id);
	assign b_user									= `AXI_TOP_INTERFACE(b_bits_user);

    assign ar_ready                                 = `AXI_TOP_INTERFACE(ar_ready);
    assign `AXI_TOP_INTERFACE(ar_valid)             = ar_valid;
    assign `AXI_TOP_INTERFACE(ar_bits_addr)         = ar_addr;
    assign `AXI_TOP_INTERFACE(ar_bits_prot)         = ar_prot;
    assign `AXI_TOP_INTERFACE(ar_bits_id)           = ar_id;
    assign `AXI_TOP_INTERFACE(ar_bits_user)         = ar_user;
    assign `AXI_TOP_INTERFACE(ar_bits_len)          = ar_len;
    assign `AXI_TOP_INTERFACE(ar_bits_size)         = ar_size;
    assign `AXI_TOP_INTERFACE(ar_bits_burst)        = ar_burst;
    assign `AXI_TOP_INTERFACE(ar_bits_lock)         = ar_lock;
    assign `AXI_TOP_INTERFACE(ar_bits_cache)        = ar_cache;
    assign `AXI_TOP_INTERFACE(ar_bits_qos)          = ar_qos;
    
    assign `AXI_TOP_INTERFACE(r_ready)              = r_ready;
    assign r_valid                                  = `AXI_TOP_INTERFACE(r_valid);
    assign r_resp                                   = `AXI_TOP_INTERFACE(r_bits_resp);
    assign r_data                                   = `AXI_TOP_INTERFACE(r_bits_data)[0];
    assign r_last                                   = `AXI_TOP_INTERFACE(r_bits_last);
    assign r_id                                     = `AXI_TOP_INTERFACE(r_bits_id);
    assign r_user                                   = `AXI_TOP_INTERFACE(r_bits_user);

    axi_rw u_axi_rw (
        .clock                          (clock),
        .reset                          (reset),

        .inst_valid_i                     (if_valid),
        .inst_ready_o                     (if_ready),
        .inst_req_i                       (if_req),
        .inst_data_read_o                    (if_data_read),
        .inst_addr_i                      (if_addr),
        .inst_size_i                      (if_size),
        .inst_resp_o                      (if_resp),

        .mem_rvalid_i                     (mem_rvalid),
        .mem_rready_o                     (mem_rready),
        //.mem_req_i                       (mem_req),
        .mem_data_read_o                    (mem_data_read),
        //.mem_data_write_i                   (mem_data_write),
        .mem_raddr_i                      (mem_raddr),
        .mem_rsize_i                      (mem_rsize),
        .mem_rresp_o                      (mem_rresp),

        .mem_wvalid_i                     (mem_wvalid),
        .mem_wready_o                     (mem_wready),
        //.mem_req_i                       (mem_req),
        //.mem_data_read_o                    (mem_data_read),
        .mem_data_write_i                   (mem_data_write),
        .mem_waddr_i                      (mem_waddr),
        .mem_wsize_i                      (mem_wsize),
        .mem_wresp_o                      (mem_wresp),
	//axi signal
        .axi_aw_ready_i                 (aw_ready),
        .axi_aw_valid_o                 (aw_valid),
        .axi_aw_addr_o                  (aw_addr),
        .axi_aw_prot_o                  (aw_prot),
        .axi_aw_id_o                    (aw_id),
        .axi_aw_user_o                  (aw_user),
        .axi_aw_len_o                   (aw_len),
        .axi_aw_size_o                  (aw_size),
        .axi_aw_burst_o                 (aw_burst),
        .axi_aw_lock_o                  (aw_lock),
        .axi_aw_cache_o                 (aw_cache),
        .axi_aw_qos_o                   (aw_qos),

        .axi_w_ready_i                  (w_ready),
        .axi_w_valid_o                  (w_valid),
        .axi_w_data_o                   (w_data[0]),
        .axi_w_strb_o                   (w_strb),
        .axi_w_last_o                   (w_last),
        .axi_w_id_o                     (w_id),
        
        .axi_b_ready_o                  (b_ready),
        .axi_b_valid_i                  (b_valid),
        .axi_b_resp_i                   (b_resp),
        .axi_b_id_i                     (b_id),
        .axi_b_user_i                   (b_user),

        .axi_ar_ready_i                 (ar_ready),
        .axi_ar_valid_o                 (ar_valid),
        .axi_ar_addr_o                  (ar_addr),
        .axi_ar_prot_o                  (ar_prot),
        .axi_ar_id_o                    (ar_id),
        .axi_ar_user_o                  (ar_user),
        .axi_ar_len_o                   (ar_len),
        .axi_ar_size_o                  (ar_size),
        .axi_ar_burst_o                 (ar_burst),
        .axi_ar_lock_o                  (ar_lock),
        .axi_ar_cache_o                 (ar_cache),
        .axi_ar_qos_o                   (ar_qos),
        
        .axi_r_ready_o                  (r_ready),
        .axi_r_valid_i                  (r_valid),
        .axi_r_resp_i                   (r_resp),
        .axi_r_data_i                   (r_data),
        .axi_r_last_i                   (r_last),
        .axi_r_id_i                     (r_id),
        .axi_r_user_i                   (r_user)
    );

// Difftest
reg cmt_wen;
reg [7:0] cmt_wdest;
reg [`REG_BUS] cmt_wdata;
reg [`REG_BUS] cmt_pc;
reg [31:0] cmt_inst;
reg cmt_valid;
reg skip;
reg trap;
reg [7:0] trap_code;
reg [63:0] cycleCnt;
reg [63:0] instrCnt;
//reg [`REG_BUS] regs_diff [0 : 31];

always @(posedge clock) begin
  if (reset) begin
    {cmt_wen, cmt_wdest, cmt_wdata, cmt_pc, cmt_inst, cmt_valid, trap, trap_code, cycleCnt, instrCnt} <= 0;
  end
  else begin
	cmt_wen <= wb_rd_wena;	
    cmt_wdest <= {3'd0, wb_rd_waddr};
    cmt_wdata <= wb_rd_data;
    cmt_pc <= wb_pc;		
    cmt_inst <= wb_inst;
    cmt_valid <= wb_inst_valid;

 //   regs_diff <= regs;
	skip <= wb_inst == 32'hb0079073;
    trap <= wb_inst[6:0] == 7'h6b;
    trap_code <= regs[10][7:0];
    cycleCnt <= 1 + cycleCnt;
    instrCnt <= wb_inst_valid + instrCnt;
  end
end

DifftestInstrCommit DifftestInstrCommit(
  .clock              (clock),
  .coreid             (0),
  .index              (0),
  .valid              (cmt_valid),
  .pc                 (cmt_pc),
  .instr              (cmt_inst),
  .skip               (skip),
  //.skip               (0),
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
  .valid              (trap),
  .code               (trap_code),
  .pc                 (cmt_pc),
  .cycleCnt           (cycleCnt),
  .instrCnt           (instrCnt)
);

DifftestCSRState DifftestCSRState(
  .clock              (clock),
  .coreid             (0),
  .priviledgeMode     (3),
  .mstatus            (mstatus),
  .sstatus            (0),
  .mepc               (mepc),
  .sepc               (0),
  .mtval              (),
  .stval              (0),
  .mtvec              (mtvec),
  .stvec              (0),
  .mcause             (mcause),
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
