`include "defines.v"

// Burst types
`define AXI_BURST_TYPE_FIXED                                2'b00
`define AXI_BURST_TYPE_INCR                                 2'b01
`define AXI_BURST_TYPE_WRAP                                 2'b10
// Access permissions
`define AXI_PROT_UNPRIVILEGED_ACCESS                        3'b000
`define AXI_PROT_PRIVILEGED_ACCESS                          3'b001
`define AXI_PROT_SECURE_ACCESS                              3'b000
`define AXI_PROT_NON_SECURE_ACCESS                          3'b010
`define AXI_PROT_DATA_ACCESS                                3'b000
`define AXI_PROT_INSTRUCTION_ACCESS                         3'b100
// Memory types (AR)
`define AXI_ARCACHE_DEVICE_NON_BUFFERABLE                   4'b0000
`define AXI_ARCACHE_DEVICE_BUFFERABLE                       4'b0001
`define AXI_ARCACHE_NORMAL_NON_CACHEABLE_NON_BUFFERABLE     4'b0010
`define AXI_ARCACHE_NORMAL_NON_CACHEABLE_BUFFERABLE         4'b0011
`define AXI_ARCACHE_WRITE_THROUGH_NO_ALLOCATE               4'b1010
`define AXI_ARCACHE_WRITE_THROUGH_READ_ALLOCATE             4'b1110
`define AXI_ARCACHE_WRITE_THROUGH_WRITE_ALLOCATE            4'b1010
`define AXI_ARCACHE_WRITE_THROUGH_READ_AND_WRITE_ALLOCATE   4'b1110
`define AXI_ARCACHE_WRITE_BACK_NO_ALLOCATE                  4'b1011
`define AXI_ARCACHE_WRITE_BACK_READ_ALLOCATE                4'b1111
`define AXI_ARCACHE_WRITE_BACK_WRITE_ALLOCATE               4'b1011
`define AXI_ARCACHE_WRITE_BACK_READ_AND_WRITE_ALLOCATE      4'b1111
// Memory types (AW)
`define AXI_AWCACHE_DEVICE_NON_BUFFERABLE                   4'b0000
`define AXI_AWCACHE_DEVICE_BUFFERABLE                       4'b0001
`define AXI_AWCACHE_NORMAL_NON_CACHEABLE_NON_BUFFERABLE     4'b0010
`define AXI_AWCACHE_NORMAL_NON_CACHEABLE_BUFFERABLE         4'b0011
`define AXI_AWCACHE_WRITE_THROUGH_NO_ALLOCATE               4'b0110
`define AXI_AWCACHE_WRITE_THROUGH_READ_ALLOCATE             4'b0110
`define AXI_AWCACHE_WRITE_THROUGH_WRITE_ALLOCATE            4'b1110
`define AXI_AWCACHE_WRITE_THROUGH_READ_AND_WRITE_ALLOCATE   4'b1110
`define AXI_AWCACHE_WRITE_BACK_NO_ALLOCATE                  4'b0111
`define AXI_AWCACHE_WRITE_BACK_READ_ALLOCATE                4'b0111
`define AXI_AWCACHE_WRITE_BACK_WRITE_ALLOCATE               4'b1111
`define AXI_AWCACHE_WRITE_BACK_READ_AND_WRITE_ALLOCATE      4'b1111

`define AXI_SIZE_BYTES_1                                    3'b000
`define AXI_SIZE_BYTES_2                                    3'b001
`define AXI_SIZE_BYTES_4                                    3'b010
`define AXI_SIZE_BYTES_8                                    3'b011
`define AXI_SIZE_BYTES_16                                   3'b100
`define AXI_SIZE_BYTES_32                                   3'b101
`define AXI_SIZE_BYTES_64                                   3'b110
`define AXI_SIZE_BYTES_128                                  3'b111


module axi_rw # (
`ifdef CACHE
    parameter RW_DATA_WIDTH     = `CACHE_BLOCK_DATA_WIDTH,		//block size !!!
`else 
    parameter RW_DATA_WIDTH     = 64,		//block size !!!
`endif
    parameter RW_ADDR_WIDTH     = 64,
    parameter AXI_DATA_WIDTH    = 64,
    parameter AXI_ADDR_WIDTH    = 64,
    parameter AXI_ID_WIDTH      = 4,
    parameter AXI_USER_WIDTH    = 1
)(
    input                               clock,
    input                               reset,

	input                               inst_valid_i,
	output                              inst_ready_o,
    input                               inst_req_i,
`ifdef CACHE
    output reg [AXI_DATA_WIDTH-1:0]        inst_data_read_o,
	output reg							   inst_dvalid,
	output reg							   inst_dlast,
`else
    output reg [RW_DATA_WIDTH-1:0]        inst_data_read_o,
`endif
    input  [AXI_DATA_WIDTH-1:0]           inst_addr_i,
    input  [2:0]                        inst_size_i,
    output [1:0]                        inst_resp_o,

	
	input                               mem_rvalid_i,
	output                              mem_rready_o,		//almost useless in cache
`ifdef CACHE
    output reg [AXI_DATA_WIDTH-1:0]        mem_data_read_o,
	output reg							   mem_dvalid,
	output reg							   mem_dlast,
`else
    output reg [RW_DATA_WIDTH-1:0]        mem_data_read_o,
`endif
    input  [AXI_DATA_WIDTH-1:0]           mem_raddr_i,
    input  [2:0]                        mem_rsize_i,
    output [1:0]                        mem_rresp_o,

	input                               mem_wvalid_i,
	output                              mem_wready_o,		//function changed in cache
    input  [RW_DATA_WIDTH-1:0]            mem_data_write_i,
    input  [AXI_DATA_WIDTH-1:0]           mem_waddr_i,
    input  [2:0]                        mem_wsize_i,
    output [1:0]                        mem_wresp_o,

    // Advanced eXtensible Interface
    input                               axi_aw_ready_i,
    output                              axi_aw_valid_o,
    output [AXI_ADDR_WIDTH-1:0]         axi_aw_addr_o,
    output [2:0]                        axi_aw_prot_o,
    output [AXI_ID_WIDTH-1:0]           axi_aw_id_o,
    output [AXI_USER_WIDTH-1:0]         axi_aw_user_o,
    output [7:0]                        axi_aw_len_o,
    output [2:0]                        axi_aw_size_o,
    output [1:0]                        axi_aw_burst_o,
    output                              axi_aw_lock_o,
    output [3:0]                        axi_aw_cache_o,
    output [3:0]                        axi_aw_qos_o,

    input                               axi_w_ready_i,
    output                              axi_w_valid_o,
    output [AXI_DATA_WIDTH-1:0]         axi_w_data_o,
    output [AXI_DATA_WIDTH/8-1:0]       axi_w_strb_o,
    output                              axi_w_last_o,
    output [AXI_ID_WIDTH-1:0]           axi_w_id_o,
    
    output                              axi_b_ready_o,
    input                               axi_b_valid_i,
    input  [1:0]                        axi_b_resp_i,
    input  [AXI_ID_WIDTH-1:0]           axi_b_id_i,
    input  [AXI_USER_WIDTH-1:0]         axi_b_user_i,

    input                               axi_ar_ready_i,
    output                              axi_ar_valid_o,
    output [AXI_ADDR_WIDTH-1:0]         axi_ar_addr_o,
    output [2:0]                        axi_ar_prot_o,
    output [AXI_ID_WIDTH-1:0]           axi_ar_id_o,			//0 for inst; 1 for data
    output [AXI_USER_WIDTH-1:0]         axi_ar_user_o,
    output [7:0]                        axi_ar_len_o,			//burst_length = len[7 : 0] + 1		INCR : 1-256, other : 1-16
    output [2:0]                        axi_ar_size_o,			//011 for 8bytes, 010 for 4 bytes
    output [1:0]                        axi_ar_burst_o,
    output                              axi_ar_lock_o,
    output [3:0]                        axi_ar_cache_o,			//
    output [3:0]                        axi_ar_qos_o,			//default 4'b0000 indicates that interface is not participating in any Qos scheme
    
    output                              axi_r_ready_o,
    input                               axi_r_valid_i,
    input  [1:0]                        axi_r_resp_i,
    input  [AXI_DATA_WIDTH-1:0]         axi_r_data_i,
    input                               axi_r_last_i,
    input  [AXI_ID_WIDTH-1:0]           axi_r_id_i,				//useless for now
    input  [AXI_USER_WIDTH-1:0]         axi_r_user_i
);

    //wire w_trans    	= mem_req_i == `REQ_WRITE;
   	wire w_trans    	= mem_wvalid_i == 1'b1;
    wire inst_r_trans 	= inst_req_i == `REQ_READ ;
	wire mem_r_trans 	= mem_rvalid_i == 1'b1;
    //wire w_valid    	= mem_valid_i & w_trans;		//only memory write
    wire w_valid    	= mem_wvalid_i;		//only memory write
    wire r_valid    	= (inst_valid_i & inst_r_trans) | mem_rvalid_i;

    // handshake
    wire aw_hs      = axi_aw_ready_i & axi_aw_valid_o;
    wire w_hs       = axi_w_ready_i  & axi_w_valid_o;
    wire b_hs       = axi_b_ready_o  & axi_b_valid_i;
    wire ar_hs      = axi_ar_ready_i & axi_ar_valid_o;
    wire r_hs       = axi_r_ready_o  & axi_r_valid_i;

    wire w_done     = w_hs & axi_w_last_o;
    wire inst_r_done    = r_hs & axi_r_last_i & (axi_r_id_i == inst_axi_id);
    wire mem_r_done     = r_hs & axi_r_last_i & (axi_r_id_i == mem_axi_id);
	//wire w_trans_done = b_hs;
	//wire mem_trans_done = w_trans ? b_hs : mem_r_done;		//TODO
	wire inst_trans_done = inst_r_done;

    
    // ------------------State Machine------------------
    parameter [1:0] W_STATE_IDLE = 2'b00, W_STATE_ADDR = 2'b01, W_STATE_WRITE = 2'b10, W_STATE_RESP = 2'b11;
    parameter [2:0] R_STATE_IDLE = 3'b000, R_STATE_IF_AR_ME_IE = 3'b001, R_STATE_IF_RD_ME_IE  = 3'b010, R_STATE_IF_RD_ME_RD = 3'b111, R_STATE_IF_RD_ME_AR = 3'b100, R_STATE_IF_IE_ME_AR = 3'b101, R_STATE_IF_IE_ME_RD = 3'b110, R_STATE_IF_AR_ME_RD = 3'b011;

    reg [1 : 0] w_state;
	reg [2 : 0] r_state;
    wire w_state_idle = w_state == W_STATE_IDLE, w_state_addr = w_state == W_STATE_ADDR, w_state_write = w_state == W_STATE_WRITE, w_state_resp = w_state == W_STATE_RESP;
    wire r_state_idle = r_state == R_STATE_IDLE, r_state_if_ar_me_ie = r_state == R_STATE_IF_AR_ME_IE, r_state_if_rd_me_ie  = r_state == R_STATE_IF_RD_ME_IE, r_state_if_rd_me_rd = r_state == R_STATE_IF_RD_ME_RD, r_state_if_rd_me_ar = r_state == R_STATE_IF_RD_ME_AR, r_state_if_ie_me_ar = r_state == R_STATE_IF_IE_ME_AR, r_state_if_ie_me_rd = r_state == R_STATE_IF_IE_ME_RD, r_state_if_ar_me_rd = r_state == R_STATE_IF_AR_ME_RD;

    reg [RW_DATA_WIDTH-1:0]            mem_data_write_r;
    // Wirte State Machine
    always @(posedge clock) begin
        if (reset) begin
            w_state <= R_STATE_IDLE;
        end
        else begin
`ifdef CACHE
                case (w_state)
                    W_STATE_IDLE:  if (w_valid)begin w_state <= W_STATE_ADDR; mem_data_write_r <= mem_data_write_i; end
                    W_STATE_ADDR:  if (aw_hs)   w_state <= W_STATE_WRITE;
                    W_STATE_WRITE: if (w_done)  w_state <= W_STATE_RESP;
                    W_STATE_RESP:  if (b_hs)    w_state <= W_STATE_IDLE;
                endcase
`else
            if (w_valid) begin
                case (w_state)
                    W_STATE_IDLE:               w_state <= W_STATE_ADDR;
                    W_STATE_ADDR:  if (aw_hs)   w_state <= W_STATE_WRITE;
                    W_STATE_WRITE: if (w_done)  w_state <= W_STATE_RESP;
                    W_STATE_RESP:  if (b_hs)    w_state <= W_STATE_IDLE;
                endcase
            end
`endif
        end
    end

    // Read State Machine
    always @(posedge clock) begin
        if (reset) begin
            r_state <= R_STATE_IDLE;
        end
        else begin
            if (r_valid) begin		//that means r_valid should keep high during whole transaction
                case (r_state)
                    R_STATE_IDLE: begin
						if(mem_rvalid_i) begin		//mem first
			        		r_state <= R_STATE_IF_IE_ME_AR;
						end
						else begin
			        		r_state <= R_STATE_IF_AR_ME_IE;
						end
					end
					R_STATE_IF_IE_ME_AR: begin
						if(ar_hs && inst_valid_i & inst_r_trans) begin
							r_state <= R_STATE_IF_AR_ME_RD;
						end
						else if(ar_hs) begin
							r_state <= R_STATE_IF_IE_ME_RD;
						end
					end
					R_STATE_IF_AR_ME_IE: begin
						if(ar_hs && mem_rvalid_i) begin
							r_state <= R_STATE_IF_RD_ME_AR;
						end
						else if(ar_hs) begin
							r_state <= R_STATE_IF_RD_ME_IE;
						end
					end
					R_STATE_IF_AR_ME_RD: begin
						if(ar_hs & ~mem_r_done) begin
							r_state <= R_STATE_IF_RD_ME_RD;	
						end
						else if(~ar_hs & mem_r_done) begin
							r_state <= R_STATE_IF_AR_ME_IE;
						end
						else if(ar_hs & mem_r_done) begin
							r_state <= R_STATE_IF_RD_ME_IE;	
						end
					end
					R_STATE_IF_IE_ME_RD: begin
						if(inst_valid_i & inst_r_trans & ~mem_r_done) begin
							r_state <= R_STATE_IF_AR_ME_RD;
						end
						else if(~(inst_valid_i & inst_r_trans) & mem_r_done) begin
							r_state <= R_STATE_IDLE;
						end
						else if(inst_valid_i & inst_r_trans & mem_r_done) begin
							r_state <= R_STATE_IF_AR_ME_IE;
						end
					end
					R_STATE_IF_RD_ME_AR: begin
						if(ar_hs & ~inst_r_done) begin
							r_state <= R_STATE_IF_RD_ME_RD;	
						end
						else if(~ar_hs & inst_r_done) begin
							r_state <= R_STATE_IF_IE_ME_AR;
						end
						else if(ar_hs & inst_r_done) begin
							r_state <= R_STATE_IF_IE_ME_RD;	
						end
					end
					R_STATE_IF_RD_ME_IE: begin
						if(mem_rvalid_i & ~inst_r_done) begin
							r_state <= R_STATE_IF_RD_ME_AR;
						end
						else if(~(mem_rvalid_i) & inst_r_done) begin
							r_state <= R_STATE_IDLE;
						end
						else if(mem_rvalid_i & inst_r_done) begin
							r_state <= R_STATE_IF_IE_ME_AR;
						end
					end
					R_STATE_IF_RD_ME_RD: begin
						//inst_r_done == 1 && mem_r_done == 1 cannot happen
						if(inst_r_done) begin
							r_state <= R_STATE_IF_IE_ME_RD;
						end
						if(mem_r_done) begin
							r_state <= R_STATE_IF_RD_ME_IE;
						end
					end
                endcase
            end
        end
    end


    // ------------------Number of transmission------------------
    reg [7:0] inst_len;
    wire inst_len_reset      = reset | (inst_r_trans & r_state_idle);
    wire inst_len_incr_en    = (inst_len != inst_axi_len) & r_hs && (axi_r_id_i == inst_axi_id);		//incre in every data transfer
    always @(posedge clock) begin
        if (inst_len_reset) begin
            inst_len <= 0;
        end
        else if (inst_len_incr_en) begin
            inst_len <= inst_len + 1;
        end
    end

	//TODO
    reg [7:0] mem_rlen;
    wire mem_rlen_reset      = reset | (mem_r_trans & r_state_idle);
    wire mem_rlen_incr_en    = (mem_rlen != mem_axi_rlen) & (r_hs && axi_r_id_i == mem_axi_id);		//incre in every data transfer
    always @(posedge clock) begin
        if (mem_rlen_reset) begin
            mem_rlen <= 0;
        end
        else if (mem_rlen_incr_en) begin
            mem_rlen <= mem_rlen + 1;
        end
    end

    reg [7:0] mem_wlen;
    wire mem_wlen_reset      = reset | (w_trans & w_state_idle);
    wire mem_wlen_incr_en    = (mem_wlen != mem_axi_wlen) & w_hs ;		//incre in every data transfer
    always @(posedge clock) begin
        if (mem_wlen_reset) begin
            mem_wlen <= 0;
        end
        else if (mem_wlen_incr_en) begin
            mem_wlen <= mem_wlen + 1;
        end
    end
    // ------------------Process Data------------------
    parameter ALIGNED_WIDTH = $clog2(AXI_DATA_WIDTH / 8);
    parameter OFFSET_WIDTH  = $clog2(AXI_DATA_WIDTH);
    parameter AXI_SIZE      = $clog2(AXI_DATA_WIDTH / 8);
    parameter MASK_WIDTH    = AXI_DATA_WIDTH * 2;
    parameter TRANS_LEN     = RW_DATA_WIDTH / AXI_DATA_WIDTH;


	/* inst data */
    wire inst_aligned            = TRANS_LEN != 1 | inst_addr_i[ALIGNED_WIDTH-1:0] == 0;
    wire inst_size_b             = inst_size_i == `SIZE_B;
    wire inst_size_h             = inst_size_i == `SIZE_H;
    wire inst_size_w             = inst_size_i == `SIZE_W;
    wire inst_size_d             = inst_size_i == `SIZE_D;
	wire inst_size_l			 = inst_size_i == `SIZE_L;
    wire [3:0] inst_addr_op1     = {{4-ALIGNED_WIDTH{1'b0}}, inst_addr_i[ALIGNED_WIDTH-1:0]};
    wire [3:0] inst_addr_op2     = ({4{inst_size_b}} & {4'b0})
                                | ({4{inst_size_h}} & {4'b1})
                                | ({4{inst_size_w}} & {4'b11})
                                | ({4{inst_size_d}} & {4'b111})
                                ;
    wire [3:0] inst_addr_end     = inst_addr_op1 + inst_addr_op2;
    wire inst_overstep           = inst_addr_end[3:ALIGNED_WIDTH] != 0;

    wire [7:0] inst_axi_len      = inst_aligned ? TRANS_LEN - 1 : {{7{1'b0}}, inst_overstep}; 
	wire [2:0] inst_axi_size     = AXI_SIZE[2:0];
    wire [AXI_ADDR_WIDTH-1:0] inst_axi_addr    = {inst_addr_i[AXI_ADDR_WIDTH-1:ALIGNED_WIDTH], {ALIGNED_WIDTH{1'b0}}};

    wire [OFFSET_WIDTH-1:0] inst_aligned_offset_l    = {{OFFSET_WIDTH-ALIGNED_WIDTH{1'b0}}, {inst_addr_i[ALIGNED_WIDTH-1:0]}} << 3;
    wire [OFFSET_WIDTH-1:0] inst_aligned_offset_h    = AXI_DATA_WIDTH - inst_aligned_offset_l;
    wire [MASK_WIDTH-1:0] inst_mask                  = (({MASK_WIDTH{inst_size_b}} & {{MASK_WIDTH-8{1'b0}}, 8'hff})
                                                    | ({MASK_WIDTH{inst_size_h}} & {{MASK_WIDTH-16{1'b0}}, 16'hffff})
                                                    | ({MASK_WIDTH{inst_size_w}} & {{MASK_WIDTH-32{1'b0}}, 32'hffffffff})
                                                    | ({MASK_WIDTH{inst_size_d}} & {{MASK_WIDTH-64{1'b0}}, 64'hffffffff_ffffffff})
                                                    ) << inst_aligned_offset_l;
    wire [AXI_DATA_WIDTH-1:0] inst_mask_l      = inst_mask[AXI_DATA_WIDTH-1:0];
    wire [AXI_DATA_WIDTH-1:0] inst_mask_h      = inst_mask[MASK_WIDTH-1:AXI_DATA_WIDTH];

    wire [AXI_ID_WIDTH-1:0] inst_axi_id        = {AXI_ID_WIDTH{1'b0}};
    wire [AXI_USER_WIDTH-1:0] inst_axi_user    = {AXI_USER_WIDTH{1'b0}};

	/* mem rdata */
    wire mem_raligned            = TRANS_LEN != 1 | mem_raddr_i[ALIGNED_WIDTH-1:0] == 0;
    wire mem_rsize_b             = mem_rsize_i == `SIZE_B;
    wire mem_rsize_h             = mem_rsize_i == `SIZE_H;
    wire mem_rsize_w             = mem_rsize_i == `SIZE_W;
    wire mem_rsize_d             = mem_rsize_i == `SIZE_D;
    wire mem_rsize_l             = mem_rsize_i == `SIZE_L;
    wire [3:0] mem_raddr_op1     = {{4-ALIGNED_WIDTH{1'b0}}, mem_raddr_i[ALIGNED_WIDTH-1:0]};
    wire [3:0] mem_raddr_op2     = ({4{mem_rsize_b}} & {4'b0})
                                | ({4{mem_rsize_h}} & {4'b1})
                                | ({4{mem_rsize_w}} & {4'b11})
                                | ({4{mem_rsize_d}} & {4'b111})
                                ;
    wire [3:0] mem_raddr_end     = mem_raddr_op1 + mem_raddr_op2;
    wire mem_roverstep           = mem_raddr_end[3:ALIGNED_WIDTH] != 0;

    //wire [7:0] mem_axi_rlen      = mem_raligned ? TRANS_LEN - 1 : {{7{1'b0}}, mem_roverstep};
    wire [7:0] mem_axi_rlen      = mem_rsize_l ? TRANS_LEN - 1 : {{7{1'b0}}, mem_roverstep};
    wire [2:0] mem_axi_rsize     = AXI_SIZE[2:0];		//always write 64 bits data
    wire [AXI_ADDR_WIDTH-1:0] mem_axi_raddr    = {mem_raddr_i[AXI_ADDR_WIDTH-1:ALIGNED_WIDTH], {ALIGNED_WIDTH{1'b0}}};
    wire [OFFSET_WIDTH-1:0] mem_raligned_offset_l    = {{OFFSET_WIDTH-ALIGNED_WIDTH{1'b0}}, {mem_raddr_i[ALIGNED_WIDTH-1:0]}} << 3;
    wire [OFFSET_WIDTH-1:0] mem_raligned_offset_h    = AXI_DATA_WIDTH - mem_raligned_offset_l;
    wire [MASK_WIDTH-1:0] mem_rmask                  = (({MASK_WIDTH{mem_rsize_b}} & {{MASK_WIDTH-8{1'b0}}, 8'hff})
                                                    | ({MASK_WIDTH{mem_rsize_h}} & {{MASK_WIDTH-16{1'b0}}, 16'hffff})
                                                    | ({MASK_WIDTH{mem_rsize_w}} & {{MASK_WIDTH-32{1'b0}}, 32'hffffffff})
                                                    | ({MASK_WIDTH{mem_rsize_d}} & {{MASK_WIDTH-64{1'b0}}, 64'hffffffff_ffffffff})
                                                    ) << mem_raligned_offset_l;
    wire [AXI_DATA_WIDTH-1:0] mem_rmask_l      = mem_rmask[AXI_DATA_WIDTH-1:0];
    wire [AXI_DATA_WIDTH-1:0] mem_rmask_h      = mem_rmask[MASK_WIDTH-1:AXI_DATA_WIDTH];

    wire [AXI_ID_WIDTH-1:0] mem_axi_id        = {{AXI_ID_WIDTH-1{1'b0}}, 1'b1};		//mem write and read use id 1
    wire [AXI_USER_WIDTH-1:0] mem_axi_user    = {AXI_USER_WIDTH{1'b0}};

	/* mem wdata */
    wire mem_waligned            = TRANS_LEN != 1 | mem_waddr_i[ALIGNED_WIDTH-1:0] == 0;
    wire mem_wsize_b             = mem_wsize_i == `SIZE_B;
    wire mem_wsize_h             = mem_wsize_i == `SIZE_H;
    wire mem_wsize_w             = mem_wsize_i == `SIZE_W;
    wire mem_wsize_d             = mem_wsize_i == `SIZE_D;
    wire mem_wsize_l             = mem_wsize_i == `SIZE_L;
    wire [3:0] mem_waddr_op1     = {{4-ALIGNED_WIDTH{1'b0}}, mem_waddr_i[ALIGNED_WIDTH-1:0]};
    wire [3:0] mem_waddr_op2     = ({4{mem_wsize_b}} & {4'b0})
                                | ({4{mem_wsize_h}} & {4'b1})
                                | ({4{mem_wsize_w}} & {4'b11})
                                | ({4{mem_wsize_d}} & {4'b111})
                                ;
    wire [3:0] mem_waddr_end     = mem_waddr_op1 + mem_waddr_op2;
    wire mem_woverstep           = mem_waddr_end[3:ALIGNED_WIDTH] != 0;

    wire [7:0] mem_axi_wlen      = mem_wsize_l ? TRANS_LEN - 1 : {{7{1'b0}}, mem_woverstep};
    wire [2:0] mem_axi_wsize     = AXI_SIZE[2:0];		//always write 64 bits data
    wire [AXI_ADDR_WIDTH-1:0] mem_axi_waddr    = {mem_waddr_i[AXI_ADDR_WIDTH-1:ALIGNED_WIDTH], {ALIGNED_WIDTH{1'b0}}};
    wire [OFFSET_WIDTH-1:0] mem_waligned_offset_l    = {{OFFSET_WIDTH-ALIGNED_WIDTH{1'b0}}, {mem_waddr_i[ALIGNED_WIDTH-1:0]}} << 3;
    wire [OFFSET_WIDTH-1:0] mem_waligned_offset_h    = AXI_DATA_WIDTH - mem_waligned_offset_l;

    wire [AXI_DATA_WIDTH/8-1:0] mem_strb     = ({8{mem_wsize_b}} & {8'b1})
                                | ({8{mem_wsize_h}} & {8'b11})
                                | ({8{mem_wsize_w}} & {8'b1111})
                                | ({8{mem_wsize_d}} & {8'b1111_1111})
                                | ({8{mem_wsize_l}} & {8'b1111_1111})
                                ;
    wire [AXI_DATA_WIDTH/8-1:0] mem_strb_l      = mem_strb << mem_waddr_i[ALIGNED_WIDTH-1 : 0]; 
    wire [AXI_DATA_WIDTH/8-1:0] mem_strb_h      = mem_strb >> (AXI_DATA_WIDTH/8 - mem_waddr_i[ALIGNED_WIDTH-1 : 0]);


    reg inst_ready;
    wire inst_ready_nxt = inst_trans_done;			//only considerate read
    wire inst_ready_en  = inst_trans_done | inst_ready;
    always @(posedge clock) begin
        if (reset) begin
            inst_ready <= 0;
        end
        else if (inst_ready_en) begin
            inst_ready <= inst_ready_nxt;		//one cycle
        end
    end
    assign inst_ready_o     = inst_ready;
`ifdef CACHE
	assign inst_dlast = inst_ready;
`else
`endif

    reg [1:0] inst_resp;
    wire inst_resp_nxt = axi_r_resp_i;
    wire inst_resp_en = inst_trans_done;
    always @(posedge clock) begin
        if (reset) begin
            inst_resp <= 0;
        end
        else if (inst_resp_en) begin
            inst_resp <= inst_resp_nxt;			//multi cycle
        end
    end
    assign inst_resp_o      = inst_resp;

    reg mem_rready;
    wire mem_rready_nxt = mem_r_done;			//write or read
    wire mem_rready_en  = mem_r_done | mem_rready;
    always @(posedge clock) begin
        if (reset) begin
            mem_rready <= 0;
        end
        else if (mem_rready_en) begin
            mem_rready <= mem_rready_nxt;		//one cycle
        end
    end
    assign mem_rready_o     = mem_rready;
`ifdef CACHE
	assign mem_dlast = mem_rready;
`else
`endif

    reg [1:0] mem_rresp;
    wire mem_rresp_nxt = axi_r_resp_i;
    wire rresp_en = mem_r_done;		
    always @(posedge clock) begin
        if (reset) begin
            mem_rresp <= 0;
        end
        else if (rresp_en) begin
            mem_rresp <= mem_rresp_nxt;			//multi cycle
        end
    end
    assign mem_rresp_o      = mem_rresp;

    reg mem_wready;
    wire mem_wready_nxt = b_hs;			//write or read
    wire mem_wready_en  = b_hs | mem_wready;
    always @(posedge clock) begin
        if (reset) begin
            mem_wready <= 0;
        end
        else if (mem_wready_en) begin
            mem_wready <= mem_wready_nxt;		//one cycle
        end
    end

    reg [1:0] mem_wresp;
    wire mem_wresp_nxt = axi_b_resp_i;
    wire wresp_en = b_hs;		
    always @(posedge clock) begin
        if (reset) begin
            mem_wresp <= 0;
        end
        else if (wresp_en) begin
            mem_wresp <= mem_wresp_nxt;			//multi cycle
        end
    end
    assign mem_wresp_o      = mem_wresp;
    // ------------------Write Transaction------------------
	// Write address channel signals
`ifdef CACHE
	assign mem_wready_o		= w_state_idle;		//tell cache can write
`else
    assign mem_wready_o     = mem_wready;		
`endif

	assign axi_aw_valid_o 	= w_state_addr;
	assign axi_aw_addr_o	= mem_axi_waddr;
    assign axi_aw_prot_o    = `AXI_PROT_UNPRIVILEGED_ACCESS | `AXI_PROT_SECURE_ACCESS | `AXI_PROT_DATA_ACCESS;
    assign axi_aw_id_o      = mem_axi_id;		//1
    assign axi_aw_user_o    = mem_axi_user;		//0
    assign axi_aw_len_o     = mem_axi_wlen;		//0 or 1(overstep)
    assign axi_aw_size_o    = mem_axi_wsize;		//8 bytes
    assign axi_aw_burst_o   = `AXI_BURST_TYPE_INCR;
    assign axi_aw_lock_o    = 1'b0;						//normal access
    assign axi_aw_cache_o   = `AXI_ARCACHE_NORMAL_NON_CACHEABLE_NON_BUFFERABLE;	
    assign axi_aw_qos_o     = 4'h0;

	// Write Data channel signals	
	assign axi_w_valid_o 	= w_state_write;
	assign axi_w_id_o		= mem_axi_id;

	//actually no need to judge axi_w_valid_o signal;
`ifdef CACHE
    wire [AXI_DATA_WIDTH-1:0] axi_w_data_l  = (mem_data_write_r << mem_waligned_offset_l);
    wire [AXI_DATA_WIDTH-1:0] axi_w_data_h  = (mem_data_write_r >> mem_waligned_offset_h);
	/*assign axi_w_data_o = axi_w_valid_o ? 
		{AXI_DATA_WIDTH{mem_wlen == 2'b00}} & mem_data_write_r[0 +: AXI_DATA_WIDTH]
	 |	({AXI_DATA_WIDTH{mem_wlen == 2'b01}} & mem_data_write_r[AXI_DATA_WIDTH +: AXI_DATA_WIDTH])
	 |	({AXI_DATA_WIDTH{mem_wlen == 2'b10}} & mem_data_write_r[2 * AXI_DATA_WIDTH +: AXI_DATA_WIDTH])
	 |	({AXI_DATA_WIDTH{mem_wlen == 2'b11}} & mem_data_write_r[3 * AXI_DATA_WIDTH +: AXI_DATA_WIDTH]) : {AXI_DATA_WIDTH{1'b0}};
	*/

	assign axi_w_data_o = axi_w_valid_o ? 
		({AXI_DATA_WIDTH{mem_wlen == 2'b00}} & (mem_wsize_l ? mem_data_write_r[0 +: AXI_DATA_WIDTH] : axi_w_data_l))
	 |	({AXI_DATA_WIDTH{mem_wlen == 2'b01}} & (mem_wsize_l ? mem_data_write_r[AXI_DATA_WIDTH +: AXI_DATA_WIDTH] :axi_w_data_h))
	 |	({AXI_DATA_WIDTH{mem_wlen == 2'b10}} & mem_data_write_r[2 * AXI_DATA_WIDTH +: AXI_DATA_WIDTH])
	 |	({AXI_DATA_WIDTH{mem_wlen == 2'b11}} & mem_data_write_r[3 * AXI_DATA_WIDTH +: AXI_DATA_WIDTH]) : {AXI_DATA_WIDTH{1'b0}};

	assign axi_w_strb_o = axi_w_valid_o ? 
		{AXI_DATA_WIDTH{mem_wlen == 2'b00}} & mem_strb_l
	 |	({AXI_DATA_WIDTH{mem_wlen == 2'b01}} & (mem_wsize_l ? 8'b1111_1111 : mem_strb_h))
	 |	({AXI_DATA_WIDTH{mem_wlen == 2'b10}} & 8'b1111_1111)
	 |	({AXI_DATA_WIDTH{mem_wlen == 2'b11}} & 8'b1111_1111) : {AXI_DATA_WIDTH/8{1'b0}};

	//assign axi_w_strb_o = axi_w_valid_o ? 8'b1111_1111  : {AXI_DATA_WIDTH/8{1'b0}};
	assign axi_w_last_o = axi_w_valid_o ? (mem_wlen == mem_axi_wlen) : 1'b0;
`else
    wire [AXI_DATA_WIDTH-1:0] axi_w_data_l  = (mem_data_write_r << mem_waligned_offset_l);
    wire [AXI_DATA_WIDTH-1:0] axi_w_data_h  = (mem_data_write_r >> mem_waligned_offset_h);
	assign axi_w_data_o = axi_w_valid_o ? (mem_wlen[0] == 1'b0 ? axi_w_data_l : axi_w_data_h) : {AXI_DATA_WIDTH{1'b0}};
	assign axi_w_strb_o = axi_w_valid_o ? (mem_wlen[0] == 1'b0 ? mem_strb_l : mem_strb_h) : {AXI_DATA_WIDTH/8{1'b0}};
	assign axi_w_last_o = axi_w_valid_o ? (mem_wlen == mem_axi_wlen) : 1'b0;

`endif

	// Write Response channel signals
	assign axi_b_ready_o = w_state_resp;
	



    
    // ------------------Read Transaction------------------

    // Read address channel signals
    assign axi_ar_valid_o   = r_state_if_ar_me_ie | r_state_if_ie_me_ar | r_state_if_rd_me_ar | r_state_if_ar_me_rd;
    assign axi_ar_addr_o    = (({AXI_ADDR_WIDTH{r_state_if_ar_me_ie | r_state_if_ar_me_rd}} & inst_axi_addr) | ({AXI_ADDR_WIDTH{r_state_if_ie_me_ar | r_state_if_rd_me_ar}} & mem_axi_raddr));		//aligned address
    assign axi_ar_prot_o    = `AXI_PROT_UNPRIVILEGED_ACCESS | `AXI_PROT_SECURE_ACCESS | `AXI_PROT_DATA_ACCESS;
    assign axi_ar_id_o      = ({AXI_ID_WIDTH{r_state_if_ar_me_ie | r_state_if_ar_me_rd}} & inst_axi_id) | ({AXI_ID_WIDTH{r_state_if_ie_me_ar | r_state_if_rd_me_ar}} & mem_axi_id);		//0
    assign axi_ar_user_o    = ({AXI_USER_WIDTH{r_state_if_ar_me_ie | r_state_if_ar_me_rd}} & inst_axi_user) | ({AXI_USER_WIDTH{r_state_if_ie_me_ar | r_state_if_rd_me_ar}} & mem_axi_user);		//0
    assign axi_ar_len_o     = ({8{r_state_if_ar_me_ie | r_state_if_ar_me_rd}} & inst_axi_len) | ({8{r_state_if_ie_me_ar | r_state_if_rd_me_ar}} & mem_axi_rlen);
    assign axi_ar_size_o    = ({3{r_state_if_ar_me_ie | r_state_if_ar_me_rd}} & inst_axi_size) | ({3{r_state_if_ie_me_ar | r_state_if_rd_me_ar}} & mem_axi_rsize);
    assign axi_ar_burst_o   = `AXI_BURST_TYPE_INCR;
    assign axi_ar_lock_o    = 1'b0;						//normal access
    assign axi_ar_cache_o   = `AXI_ARCACHE_NORMAL_NON_CACHEABLE_NON_BUFFERABLE;	//read from final destination and transactions are modifiable
    assign axi_ar_qos_o     = 4'h0;

    // Read data channel signals
    assign axi_r_ready_o    = r_state_if_ar_me_rd | r_state_if_ie_me_rd | r_state_if_rd_me_ar | r_state_if_rd_me_ie | r_state_if_rd_me_rd;

	//mux by id
	//interleave enable

`ifdef CACHE
	/* inst */
	always @(posedge clock) begin
		if (reset) begin
			inst_data_read_o[0 +:AXI_DATA_WIDTH] <= 0;
			inst_dvalid <= 1'b0;
		end
		else if (r_hs && axi_r_id_i == inst_axi_id) begin
			inst_data_read_o[AXI_DATA_WIDTH-1:0] <= axi_r_data_i;
			inst_dvalid <= 1'b1;
		end
		else begin
			inst_data_read_o[0 +:AXI_DATA_WIDTH] <= 0;
			inst_dvalid <= 1'b0;
		end
	end
	/* mem */
	always @(posedge clock) begin
		if (reset) begin
			mem_data_read_o[0 +:AXI_DATA_WIDTH] <= 0;
			mem_dvalid <= 1'b0;
		end
		else if (r_hs && axi_r_id_i == mem_axi_id) begin
			mem_data_read_o[AXI_DATA_WIDTH-1:0] <= axi_r_data_i;
			mem_dvalid <= 1'b1;
		end
		else begin
			mem_data_read_o[0 +:AXI_DATA_WIDTH] <= 0;
			mem_dvalid <= 1'b0;
		end
	end
`else
    wire [AXI_DATA_WIDTH-1:0] axi_r_data_l  = (axi_r_id_i == inst_axi_id) ? ((axi_r_data_i & inst_mask_l) >> inst_aligned_offset_l) : ((axi_r_data_i & mem_rmask_l) >> mem_raligned_offset_l);
    wire [AXI_DATA_WIDTH-1:0] axi_r_data_h  = (axi_r_id_i == inst_axi_id) ? ((axi_r_data_i & inst_mask_h) << inst_aligned_offset_h) : ((axi_r_data_i & mem_rmask_h) << mem_raligned_offset_h);
	/* inst */
    generate
        for (genvar i = 0; i < TRANS_LEN; i += 1) begin
            always @(posedge clock) begin
                if (reset) begin
                    inst_data_read_o[i*AXI_DATA_WIDTH+:AXI_DATA_WIDTH] <= 0;
                end
                else if (r_hs && axi_r_id_i == inst_axi_id) begin
                    if (~inst_aligned & inst_overstep) begin
                        if (inst_len[0]) begin
                            inst_data_read_o[AXI_DATA_WIDTH-1:0] <= inst_data_read_o[AXI_DATA_WIDTH-1:0] | axi_r_data_h;
                        end
                        else begin
                            inst_data_read_o[AXI_DATA_WIDTH-1:0] <= axi_r_data_l;
                        end
                    end
                    else if (inst_len == i) begin
                        inst_data_read_o[i*AXI_DATA_WIDTH+:AXI_DATA_WIDTH] <= axi_r_data_l;
                    end
                end
            end
        end
    endgenerate
	/* mem */
    generate
        for (genvar i = 0; i < TRANS_LEN; i += 1) begin
            always @(posedge clock) begin
                if (reset) begin
                    mem_data_read_o[i*AXI_DATA_WIDTH+:AXI_DATA_WIDTH] <= 0;
                end
                else if (r_hs && axi_r_id_i == mem_axi_id) begin
                    if (~mem_raligned & mem_roverstep) begin
                        if (mem_rlen[0]) begin
                            mem_data_read_o[AXI_DATA_WIDTH-1:0] <= mem_data_read_o[AXI_DATA_WIDTH-1:0] | axi_r_data_h;
                        end
                        else begin
                            mem_data_read_o[AXI_DATA_WIDTH-1:0] <= axi_r_data_l;
                        end
                    end
                    else if (mem_rlen == i) begin
                        mem_data_read_o[i*AXI_DATA_WIDTH+:AXI_DATA_WIDTH] <= axi_r_data_l;
                    end
                end
            end
        end
    endgenerate
`endif

endmodule
