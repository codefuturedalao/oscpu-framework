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


module axi_slave # (
    parameter RW_DATA_WIDTH     = 64,
    parameter RW_ADDR_WIDTH     = 64,
    parameter AXI_DATA_WIDTH    = 64,
    parameter AXI_ADDR_WIDTH    = 64,
    parameter AXI_ID_WIDTH      = 4,
    parameter AXI_USER_WIDTH    = 1
)(
    input                               clk,
    input                               rst,

	output                               rw_valid_o,
	input                              rw_ready_i,
    output                               rw_req_o,
    input reg [RW_DATA_WIDTH:0]        data_read_i,
    output  [RW_DATA_WIDTH:0]            data_write_o,
    output  [AXI_DATA_WIDTH:0]           rw_addr_o,
    //output  [1:0]                        rw_size_o,
    output [AXI_DATA_WIDTH/8-1:0]       data_write_strb_o,
    input [1:0]                        rw_resp_i,

    // Advanced eXtensible Interface
    output                               axi_aw_ready_o,
    input                              axi_aw_valid_i,
    input [AXI_ADDR_WIDTH-1:0]         axi_aw_addr_i,
    input [2:0]                        axi_aw_prot_i,
    input [AXI_ID_WIDTH-1:0]           axi_aw_id_i,
    input [AXI_USER_WIDTH-1:0]         axi_aw_user_i,
    input [7:0]                        axi_aw_len_i,
    input [2:0]                        axi_aw_size_i,
    input [1:0]                        axi_aw_burst_i,
    input                              axi_aw_lock_i,
    input [3:0]                        axi_aw_cache_i,
    input [3:0]                        axi_aw_qos_i,
//    input [3:0]                        axi_aw_region_i,

    output                               axi_w_ready_o,
    input                              axi_w_valid_i,
    input [AXI_DATA_WIDTH-1:0]         axi_w_data_i,
    input [AXI_DATA_WIDTH/8-1:0]       axi_w_strb_i,
    input                              axi_w_last_i,
    //input [AXI_USER_WIDTH-1:0]         axi_w_user_i,
    
    input                              axi_b_ready_i,
    output                               axi_b_valid_o,
    output  [1:0]                        axi_b_resp_o,
    output  [AXI_ID_WIDTH-1:0]           axi_b_id_o,
    output  [AXI_USER_WIDTH-1:0]         axi_b_user_o,

    output                               axi_ar_ready_o,
    input                              axi_ar_valid_i,
    input [AXI_ADDR_WIDTH-1:0]         axi_ar_addr_i,
    input [2:0]                        axi_ar_prot_i,
    input [AXI_ID_WIDTH-1:0]           axi_ar_id_i,
    input [AXI_USER_WIDTH-1:0]         axi_ar_user_i,
    input [7:0]                        axi_ar_len_i,
    input [2:0]                        axi_ar_size_i,
    input [1:0]                        axi_ar_burst_i,
    input                              axi_ar_lock_i,
    input [3:0]                        axi_ar_cache_i,
    input [3:0]                        axi_ar_qos_i,
    //input [3:0]                        axi_ar_region_i,
    
    input                              axi_r_ready_i,
    output                               axi_r_valid_o,
    output  [1:0]                        axi_r_resp_o,
    output  [AXI_DATA_WIDTH-1:0]         axi_r_data_o,
    output                               axi_r_last_o,
    output  [AXI_ID_WIDTH-1:0]           axi_r_id_o,
    output  [AXI_USER_WIDTH-1:0]         axi_r_user_o
);

    //wire w_trans    = rw_req_o == `REQ_WRITE;
    //wire r_trans    = rw_req_o == `REQ_READ;
    //wire w_valid    = rw_valid_o & w_trans;
    //wire r_valid    = rw_valid_o & r_trans;

    // handshake
    wire aw_hs      = axi_aw_ready_o & axi_aw_valid_i;
    wire w_hs       = axi_w_ready_o  & axi_w_valid_i;
    wire b_hs       = axi_b_ready_i  & axi_b_valid_o;
    wire ar_hs      = axi_ar_ready_o & axi_ar_valid_i;
    wire r_hs       = axi_r_ready_i  & axi_r_valid_o;

    wire w_done     = w_hs & axi_w_last_i;
    wire r_done     = r_hs & axi_r_last_o;
    //wire trans_done = w_trans ? b_hs : r_done;

    
    // ------------------State Machine------------------
    parameter [1:0] W_STATE_IDLE = 2'b00, W_STATE_ADDR = 2'b01, W_STATE_WRITE = 2'b10, W_STATE_RESP = 2'b11;
    parameter [1:0] R_STATE_IDLE = 2'b00, R_STATE_ADDR = 2'b01, R_STATE_READ  = 2'b10;

    reg [1:0] w_state, r_state;
    wire w_state_idle = w_state == W_STATE_IDLE, w_state_addr = w_state == W_STATE_ADDR, w_state_write = w_state == W_STATE_WRITE, w_state_resp = w_state == W_STATE_RESP;
    wire r_state_idle = r_state == R_STATE_IDLE, r_state_addr = r_state == R_STATE_ADDR, r_state_read  = r_state == R_STATE_READ;

	reg [AXI_ID_WIDTH - 1 : 0] wid_r;
	reg [AXI_ADDR_WIDTH - 1 : 0] waddr_r;
	reg [AXI_ADDR_WIDTH - 1 : 0] wsize_r;
    // Wirte State Machine
    always @(posedge clk) begin
        if (rst == 1'b1) begin
            w_state <= W_STATE_IDLE;
        end
        else begin
            //if (w_valid) begin
                case (w_state)
                    W_STATE_IDLE:  if (axi_aw_valid_i)	w_state <= W_STATE_ADDR;
                    W_STATE_ADDR:  if (aw_hs) begin
										 wid_r <= axi_aw_id_i;
										 waddr_r <= axi_aw_addr_i;
										 wsize_r <= axi_aw_size_i;
								 		 w_state <= W_STATE_WRITE;
								   end
                    W_STATE_WRITE: if (w_done)  		w_state <= W_STATE_RESP;
                    W_STATE_RESP:  if (b_hs)    		w_state <= W_STATE_IDLE;
                endcase
            //end
        end
    end

	reg [AXI_ID_WIDTH - 1 : 0] rid_r;
	reg [AXI_ADDR_WIDTH - 1 : 0] raddr_r;
    // Read State Machine
    always @(posedge clk) begin
        if (rst == 1'b1) begin
            r_state <= R_STATE_IDLE;
        end
        else begin
            //if (r_valid) begin
                case (r_state)
                    R_STATE_IDLE: if(axi_ar_valid_i)    r_state <= R_STATE_ADDR;
                    R_STATE_ADDR: if (ar_hs) begin
										rid_r <= axi_ar_id_i;
										raddr_r <= axi_ar_addr_i;
					   					r_state <= R_STATE_READ;
								  end
                    R_STATE_READ: if (r_done)   		r_state <= R_STATE_IDLE;
                    default:;
                endcase
        end
    end




    // ------------------Write Transaction------------------
	assign rw_valid_o 	 = (w_state_write & axi_w_valid_i) | (r_state_read);
	assign rw_req_o 	 = (w_state_write & axi_w_valid_i);		//1: write
	assign data_write_o  = axi_w_data_i;
	assign data_write_strb_o  = axi_w_strb_i;
	assign rw_addr_o 	 = {AXI_DATA_WIDTH{w_state_write}} & waddr_r
						  |{AXI_DATA_WIDTH{r_state_read}}  & raddr_r;

	assign axi_aw_ready_o = w_state_addr;
	assign axi_w_ready_o  = rw_ready_i;
	assign axi_b_valid_o  = w_state_resp;
	assign axi_b_resp_o	  = rw_resp_i;
	assign axi_b_id_o	  = wid_r;
	assign axi_b_user_o   = {AXI_USER_WIDTH{1'b0}};

    
    // ------------------Read Transaction------------------
	assign axi_ar_ready_o  = r_state_addr;
	assign axi_r_valid_o   = rw_ready_i;
	assign axi_r_resp_o	   = rw_resp_i;
	assign axi_r_data_o    = data_read_i;
	assign axi_r_last_o	   = r_state_read;
	assign axi_r_id_o	   = rid_r;
	assign axi_r_user_o	   = {AXI_USER_WIDTH{1'b0}};


endmodule
