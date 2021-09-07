`include "defines.v"


module crossbar1_2 # (
    parameter RW_ADDR_WIDTH     = 64,
    parameter AXI_DATA_WIDTH    = 64,
    parameter AXI_ADDR_WIDTH    = 64,
    parameter AXI_ID_WIDTH      = 4,
    parameter AXI_USER_WIDTH    = 1
)(
    input                               clk,
    input                               rst,

    // Advanced eXtensible Interface
	//slave
    output                             m_axi_aw_ready_o,
    input                              m_axi_aw_valid_i,
    input [AXI_ADDR_WIDTH-1:0]         m_axi_aw_addr_i,
    input [2:0]                        m_axi_aw_prot_i,
    input [AXI_ID_WIDTH-1:0]           m_axi_aw_id_i,
    input [AXI_USER_WIDTH-1:0]         m_axi_aw_user_i,
    input [7:0]                        m_axi_aw_len_i,
    input [2:0]                        m_axi_aw_size_i,
    input [1:0]                        m_axi_aw_burst_i,
    input                              m_axi_aw_lock_i,
    input [3:0]                        m_axi_aw_cache_i,
    input [3:0]                        m_axi_aw_qos_i,
   // input [3:0]                        m_axi_aw_region_i,

    output                               m_axi_w_ready_o,
    input                              m_axi_w_valid_i,
    input [AXI_DATA_WIDTH-1:0]         m_axi_w_data_i,
    input [AXI_DATA_WIDTH/8-1:0]       m_axi_w_strb_i,
    input                              m_axi_w_last_i,
    //input [AXI_USER_WIDTH-1:0]         m_axi_w_user_i,
    
    input                              m_axi_b_ready_i,
    output                               m_axi_b_valid_o,
    output  [1:0]                        m_axi_b_resp_o,
    output  [AXI_ID_WIDTH-1:0]           m_axi_b_id_o,
    output  [AXI_USER_WIDTH-1:0]         m_axi_b_user_o,

    output                               m_axi_ar_ready_o,
    input                              m_axi_ar_valid_i,
    input [AXI_ADDR_WIDTH-1:0]         m_axi_ar_addr_i,
    input [2:0]                        m_axi_ar_prot_i,
    input [AXI_ID_WIDTH-1:0]           m_axi_ar_id_i,
    input [AXI_USER_WIDTH-1:0]         m_axi_ar_user_i,
    input [7:0]                        m_axi_ar_len_i,
    input [2:0]                        m_axi_ar_size_i,
    input [1:0]                        m_axi_ar_burst_i,
    input                              m_axi_ar_lock_i,
    input [3:0]                        m_axi_ar_cache_i,
    input [3:0]                        m_axi_ar_qos_i,
    
    input                              m_axi_r_ready_i,
    output                               m_axi_r_valid_o,
    output  [1:0]                        m_axi_r_resp_o,
    output  [AXI_DATA_WIDTH-1:0]         m_axi_r_data_o,
    output                               m_axi_r_last_o,
    output  [AXI_ID_WIDTH-1:0]           m_axi_r_id_o,
    output  [AXI_USER_WIDTH-1:0]         m_axi_r_user_o,

	//two master
    input                               axi_aw_ready_i [1 : 0],
    output                              axi_aw_valid_o [1 : 0],
    output [AXI_ADDR_WIDTH-1:0]         axi_aw_addr_o [1 : 0],
    output [2:0]                        axi_aw_prot_o [1 : 0],
    output [AXI_ID_WIDTH-1:0]           axi_aw_id_o [1 : 0],
    output [AXI_USER_WIDTH-1:0]         axi_aw_user_o [1 : 0],
    output [7:0]                        axi_aw_len_o [1 : 0],
    output [2:0]                        axi_aw_size_o [1 : 0],
    output [1:0]                        axi_aw_burst_o [1 : 0],
    output                              axi_aw_lock_o [1 : 0],
    output [3:0]                        axi_aw_cache_o [1 : 0],
    output [3:0]                        axi_aw_qos_o [1 : 0],

    input                               axi_w_ready_i [1 : 0],
    output                              axi_w_valid_o [1 : 0],
    output [AXI_DATA_WIDTH-1:0]         axi_w_data_o [1 : 0],
    output [AXI_DATA_WIDTH/8-1:0]       axi_w_strb_o [1 : 0],
    output                              axi_w_last_o [1 : 0],
    //output [AXI_ID_WIDTH-1:0]           axi_w_id_o [1 : 0],
    
    output                              axi_b_ready_o [1 : 0],
    input                               axi_b_valid_i [1 : 0],
    input  [1:0]                        axi_b_resp_i [1 : 0],
    input  [AXI_ID_WIDTH-1:0]           axi_b_id_i [1 : 0],
    input  [AXI_USER_WIDTH-1:0]         axi_b_user_i [1 : 0],

    input                               axi_ar_ready_i [1 : 0],
    output                              axi_ar_valid_o [1 : 0],
    output [AXI_ADDR_WIDTH-1:0]         axi_ar_addr_o [1 : 0],
    output [2:0]                        axi_ar_prot_o [1 : 0],
    output [AXI_ID_WIDTH-1:0]           axi_ar_id_o [1 : 0],			//0 for inst; 1 for data
    output [AXI_USER_WIDTH-1:0]         axi_ar_user_o [1 : 0],
    output [7:0]                        axi_ar_len_o [1 : 0],			//burst_length = len[7 : 0] + 1		INCR : 1-256, other : 1-16
    output [2:0]                        axi_ar_size_o [1 : 0],			//011 for 8bytes, 010 for 4 bytes
    output [1:0]                        axi_ar_burst_o [1 : 0],
    output                              axi_ar_lock_o [1 : 0],
    output [3:0]                        axi_ar_cache_o [1 : 0],			//
    output [3:0]                        axi_ar_qos_o [1 : 0],			//default 4'b0000 indicates that interface is not participating in any Qos scheme
    
    output                              axi_r_ready_o [1 : 0],
    input                               axi_r_valid_i [1 : 0],
    input  [1:0]                        axi_r_resp_i [1 : 0],
    input  [AXI_DATA_WIDTH-1:0]         axi_r_data_i [1 : 0],
    input                               axi_r_last_i [1 : 0],
    input  [AXI_ID_WIDTH-1:0]           axi_r_id_i [1 : 0],				//useless for now
    input  [AXI_USER_WIDTH-1:0]         axi_r_user_i [1 : 0]
);

	

	/* state machine */
	parameter [3 : 0] IDLE = 4'b0000, R_SLAVE0_ADDR = 4'b0001, R_SLAVE1_ADDR = 4'b0010, R_SLAVE0_DATA = 4'b0011, R_SLAVE1_DATA = 4'b0100, R_SLAVE0_DATA_SLAVE0_ADDR = 4'b0101, R_SLAVE0_DATA_SLAVE1_ADDR = 4'b0110, R_SLAVE0_ADDR_SLAVE1_DATA = 4'b0111, R_SLAVE1_DATA_SLAVE1_ADDR = 4'b1000, R_SLAVE0_DATA_SLAVE0_DATA = 4'b1001, R_SLAVE0_DATA_SLAVE1_DATA = 4'b1010, R_SLAVE1_DATA_SLAVE1_DATA = 4'b1011;

	reg [3 : 0] r_state;
	wire idle = r_state == IDLE, r_slave0_addr = r_state == R_SLAVE0_ADDR, r_slave1_addr = r_state == R_SLAVE1_ADDR, r_slave0_data = r_state == R_SLAVE0_DATA, r_slave1_data = r_state == R_SLAVE1_DATA, r_slave0_data_slave0_addr = r_state == R_SLAVE0_DATA_SLAVE0_ADDR, r_slave0_data_slave1_addr = r_state == R_SLAVE0_DATA_SLAVE1_ADDR, r_slave0_addr_slave1_data = r_state == R_SLAVE0_ADDR_SLAVE1_DATA, r_slave1_data_slave1_addr = r_state == R_SLAVE1_DATA_SLAVE1_ADDR, r_slave0_data_slave0_data = r_state == R_SLAVE0_DATA_SLAVE0_DATA, r_slave0_data_slave1_data = r_state == R_SLAVE0_DATA_SLAVE1_DATA, r_slave1_data_slave1_data = r_state == R_SLAVE1_DATA_SLAVE1_DATA;

	wire slave0_ar_hs = axi_ar_ready_i[0] & m_axi_ar_valid_i;
	wire slave1_ar_hs = axi_ar_ready_i[1] & m_axi_ar_valid_i;
	wire slave0_r_done = axi_r_valid_i[0] & m_axi_r_ready_i & axi_r_last_i[0];
	wire slave1_r_done = axi_r_valid_i[1] & m_axi_r_ready_i & axi_r_last_i[1];

	always
		@(posedge clk) begin
			if(rst == 1'b1) begin
				r_state <= IDLE;
			end
			else begin
			case(r_state)
				IDLE: begin
					if(m_axi_ar_valid_i == 1'b1 && m_axi_ar_addr_i <= 32'h0200_ffff && m_axi_ar_addr_i >= 32'h0200_0000 ) begin
						r_state <= R_SLAVE0_ADDR;
					end
					else if(m_axi_ar_valid_i == 1'b1 ) begin
						r_state <= R_SLAVE1_ADDR;
					end
				end
				R_SLAVE0_ADDR: begin
					if(slave0_ar_hs) begin
						r_state <= R_SLAVE0_DATA;
					end
				end
				R_SLAVE1_ADDR: begin
					if(slave1_ar_hs) begin
						r_state <= R_SLAVE1_DATA;
					end
				end
				R_SLAVE0_DATA: begin
					if(m_axi_ar_valid_i == 1'b1 && m_axi_ar_addr_i <= 32'h0200_ffff && m_axi_ar_addr_i >= 32'h0200_0000 && slave0_r_done == 1'b0) begin
						r_state <= R_SLAVE0_DATA_SLAVE0_ADDR;
					end
					else if(m_axi_ar_valid_i == 1'b1 && m_axi_ar_addr_i <= 32'h0200_ffff && m_axi_ar_addr_i >= 32'h0200_0000 && slave0_r_done == 1'b1) begin
						r_state <= R_SLAVE0_ADDR;
					end
					else if(m_axi_ar_valid_i == 1'b1 && slave0_r_done == 1'b0) begin
						r_state <= R_SLAVE0_DATA_SLAVE1_ADDR;
					end
					else if(m_axi_ar_valid_i == 1'b1 && slave0_r_done == 1'b1) begin
						r_state <= R_SLAVE1_ADDR;
					end
					else if(slave0_r_done == 1'b1) begin
						r_state <= IDLE;
					end
				end
				R_SLAVE1_DATA: begin
					if(m_axi_ar_valid_i == 1'b1 && m_axi_ar_addr_i <= 32'h0200_ffff && m_axi_ar_addr_i >= 32'h0200_0000 && slave1_r_done == 1'b0) begin
						r_state <= R_SLAVE0_ADDR_SLAVE1_DATA;
					end
					else if(m_axi_ar_valid_i == 1'b1 && m_axi_ar_addr_i <= 32'h0200_ffff && m_axi_ar_addr_i >= 32'h0200_0000 && slave1_r_done == 1'b1) begin
						r_state <= R_SLAVE0_ADDR;
					end
					else if(m_axi_ar_valid_i == 1'b1 && slave1_r_done == 1'b0) begin
						r_state <= R_SLAVE1_DATA_SLAVE1_ADDR;
					end
					else if(m_axi_ar_valid_i == 1'b1 && slave1_r_done == 1'b1) begin
						r_state <= R_SLAVE1_ADDR;
					end
					else if(slave1_r_done == 1'b1) begin
						r_state <= IDLE;
					end
				end
				R_SLAVE0_DATA_SLAVE0_ADDR: begin
					if(slave0_ar_hs == 1'b1 && slave0_r_done == 1'b1) begin
						r_state <= R_SLAVE0_DATA;
					end
					else if(slave0_ar_hs == 1'b1 && slave0_r_done == 1'b0) begin
						r_state <= R_SLAVE0_DATA_SLAVE0_DATA;
					end
					else if(slave0_ar_hs == 1'b0 && slave0_r_done == 1'b1) begin
						r_state <= R_SLAVE0_ADDR;
					end
				end
				R_SLAVE0_DATA_SLAVE1_ADDR: begin
					if(slave1_ar_hs == 1'b1 && slave0_r_done == 1'b1) begin
						r_state <= R_SLAVE1_DATA;
					end
					else if(slave1_ar_hs == 1'b1 && slave0_r_done == 1'b0) begin
						r_state <= R_SLAVE0_DATA_SLAVE1_DATA;
					end
					else if(slave1_ar_hs == 1'b0 && slave0_r_done == 1'b1) begin
						r_state <= R_SLAVE1_ADDR;
					end
				end
				R_SLAVE0_ADDR_SLAVE1_DATA: begin
					if(slave0_ar_hs == 1'b1 && slave1_r_done == 1'b1) begin
						r_state <= R_SLAVE0_DATA;
					end
					else if(slave0_ar_hs == 1'b1 && slave1_r_done == 1'b0) begin
						r_state <= R_SLAVE0_DATA_SLAVE1_DATA;
					end
					else if(slave0_ar_hs == 1'b0 && slave1_r_done == 1'b1) begin
						r_state <= R_SLAVE0_ADDR;
					end
				end
				R_SLAVE1_DATA_SLAVE1_ADDR: begin
					if(slave1_ar_hs == 1'b1 && slave1_r_done == 1'b1) begin
						r_state <= R_SLAVE1_DATA;
					end
					else if(slave1_ar_hs == 1'b1 && slave1_r_done == 1'b0) begin
						r_state <= R_SLAVE1_DATA_SLAVE1_DATA;
					end
					else if(slave1_ar_hs == 1'b0 && slave1_r_done == 1'b1) begin
						r_state <= R_SLAVE1_ADDR;
					end
				end
				R_SLAVE0_DATA_SLAVE0_DATA: begin
					if(slave0_r_done == 1'b1) begin
						r_state <= R_SLAVE0_DATA;
					end
				end
				R_SLAVE0_DATA_SLAVE1_DATA: begin
					if(slave0_r_done == 1'b1) begin
						r_state <= R_SLAVE1_DATA;
					end
	//				else if(slave1_r_done == 1'b1) begin
	//					r_state <= R_SLAVE0_DATA;
	//				end
				end
				R_SLAVE1_DATA_SLAVE1_DATA: begin
					if(slave1_r_done == 1'b1) begin
						r_state <= R_SLAVE1_DATA;
					end
				end
				default: begin end
			endcase
			end
		end

	assign m_axi_ar_ready_o    = (r_slave0_addr | r_slave0_data_slave0_addr | r_slave0_addr_slave1_data) & axi_ar_ready_i[0]
							|  (r_slave1_addr | r_slave0_data_slave1_addr | r_slave1_data_slave1_addr ) & axi_ar_ready_i[1];

	assign axi_ar_valid_o[0] = (r_slave0_addr | r_slave0_data_slave0_addr | r_slave0_addr_slave1_data) & m_axi_ar_valid_i;
	assign axi_ar_addr_o[0]  = {AXI_ADDR_WIDTH{(r_slave0_addr | r_slave0_data_slave0_addr | r_slave0_addr_slave1_data)}} & m_axi_ar_addr_i;
	assign axi_ar_prot_o[0] = {3{(r_slave0_addr | r_slave0_data_slave0_addr | r_slave0_addr_slave1_data)}} & m_axi_ar_prot_i;
	assign axi_ar_id_o[0]  = {AXI_ID_WIDTH{(r_slave0_addr | r_slave0_data_slave0_addr | r_slave0_addr_slave1_data)}} & m_axi_ar_id_i;
	assign axi_ar_user_o[0] = {AXI_USER_WIDTH{(r_slave0_addr | r_slave0_data_slave0_addr | r_slave0_addr_slave1_data)}} & m_axi_ar_user_i;
	assign axi_ar_len_o[0]  = {8{(r_slave0_addr | r_slave0_data_slave0_addr | r_slave0_addr_slave1_data)}} & m_axi_ar_len_i;
	assign axi_ar_size_o[0] = {3{(r_slave0_addr | r_slave0_data_slave0_addr | r_slave0_addr_slave1_data)}} & m_axi_ar_size_i;
	assign axi_ar_burst_o[0]  = {2{(r_slave0_addr | r_slave0_data_slave0_addr | r_slave0_addr_slave1_data)}} & m_axi_ar_burst_i;
	assign axi_ar_lock_o[0]  = (r_slave0_addr | r_slave0_data_slave0_addr | r_slave0_addr_slave1_data) & m_axi_ar_lock_i;
	assign axi_ar_cache_o[0]  = {4{(r_slave0_addr | r_slave0_data_slave0_addr | r_slave0_addr_slave1_data)}} & m_axi_ar_cache_i;
	assign axi_ar_qos_o[0]  = {4{(r_slave0_addr | r_slave0_data_slave0_addr | r_slave0_addr_slave1_data)}} & m_axi_ar_qos_i;


	assign axi_ar_valid_o[1] = (r_slave1_addr | r_slave0_data_slave1_addr | r_slave1_data_slave1_addr) & m_axi_ar_valid_i;
	assign axi_ar_addr_o[1]  = {AXI_ADDR_WIDTH{(r_slave1_addr | r_slave0_data_slave1_addr | r_slave1_data_slave1_addr)}} & m_axi_ar_addr_i;
	assign axi_ar_prot_o[1] = {3{(r_slave1_addr | r_slave0_data_slave1_addr | r_slave1_data_slave1_addr)}} & m_axi_ar_prot_i;
	assign axi_ar_id_o[1]  = {AXI_ID_WIDTH{(r_slave1_addr | r_slave0_data_slave1_addr | r_slave1_data_slave1_addr)}} & m_axi_ar_id_i;
	assign axi_ar_user_o[1] = {AXI_USER_WIDTH{(r_slave1_addr | r_slave0_data_slave1_addr | r_slave1_data_slave1_addr)}} & m_axi_ar_user_i;
	assign axi_ar_len_o[1]  = {8{(r_slave1_addr | r_slave0_data_slave1_addr | r_slave1_data_slave1_addr)}} & m_axi_ar_len_i;
	assign axi_ar_size_o[1] = {3{(r_slave1_addr | r_slave0_data_slave1_addr | r_slave1_data_slave1_addr)}} & m_axi_ar_size_i;
	assign axi_ar_burst_o[1]  = {2{(r_slave1_addr | r_slave0_data_slave1_addr | r_slave1_data_slave1_addr)}} & m_axi_ar_burst_i;
	assign axi_ar_lock_o[1]  = (r_slave1_addr | r_slave0_data_slave1_addr | r_slave1_data_slave1_addr) & m_axi_ar_lock_i;
	assign axi_ar_cache_o[1]  = {4{(r_slave1_addr | r_slave0_data_slave1_addr | r_slave1_data_slave1_addr)}} & m_axi_ar_cache_i;
	assign axi_ar_qos_o[1]  = {4{(r_slave1_addr | r_slave0_data_slave1_addr | r_slave1_data_slave1_addr)}} & m_axi_ar_qos_i;


	assign axi_r_ready_o[0] = (r_slave0_data | r_slave0_data_slave1_addr | r_slave0_data_slave0_addr | r_slave0_data_slave1_data) & m_axi_r_ready_i;

	assign axi_r_ready_o[1] = (r_slave1_data | r_slave1_data_slave1_addr | r_slave0_addr_slave1_data | r_slave1_data_slave1_data) & m_axi_r_ready_i;

	assign m_axi_r_valid_o = (r_slave0_data | r_slave0_data_slave1_addr | r_slave0_data_slave0_addr | r_slave0_data_slave0_data & r_slave0_data_slave1_data) & axi_r_valid_i[0]
						|  (r_slave1_data | r_slave1_data_slave1_addr | r_slave0_addr_slave1_data | r_slave1_data_slave1_data) & axi_r_valid_i[1];
	assign m_axi_r_resp_o = {2{(r_slave0_data | r_slave0_data_slave1_addr | r_slave0_data_slave0_addr | r_slave0_data_slave0_data & r_slave0_data_slave1_data)}} & axi_r_resp_i[0]
						|  {2{(r_slave1_data | r_slave1_data_slave1_addr | r_slave0_addr_slave1_data | r_slave1_data_slave1_data)}} & axi_r_resp_i[1];
	assign m_axi_r_data_o = {AXI_DATA_WIDTH{(r_slave0_data | r_slave0_data_slave1_addr | r_slave0_data_slave0_addr | r_slave0_data_slave0_data & r_slave0_data_slave1_data)}} & axi_r_data_i[0]
						|  {AXI_DATA_WIDTH{(r_slave1_data | r_slave1_data_slave1_addr | r_slave0_addr_slave1_data | r_slave1_data_slave1_data)}} & axi_r_data_i[1];
	assign m_axi_r_last_o = (r_slave0_data | r_slave0_data_slave1_addr | r_slave0_data_slave0_addr | r_slave0_data_slave0_data & r_slave0_data_slave1_data) & axi_r_last_i[0]
						|  (r_slave1_data | r_slave1_data_slave1_addr | r_slave0_addr_slave1_data | r_slave1_data_slave1_data) & axi_r_last_i[1];
	assign m_axi_r_id_o = {AXI_ID_WIDTH{(r_slave0_data | r_slave0_data_slave1_addr | r_slave0_data_slave0_addr | r_slave0_data_slave0_data & r_slave0_data_slave1_data)}} & axi_r_id_i[0]
						|  {AXI_ID_WIDTH{(r_slave1_data | r_slave1_data_slave1_addr | r_slave0_addr_slave1_data | r_slave1_data_slave1_data)}} & axi_r_id_i[1];
	assign m_axi_r_user_o = {AXI_USER_WIDTH{(r_slave0_data | r_slave0_data_slave1_addr | r_slave0_data_slave0_addr | r_slave0_data_slave0_data & r_slave0_data_slave1_data)}} & axi_r_user_i[0]
						|  {AXI_USER_WIDTH{(r_slave1_data | r_slave1_data_slave1_addr | r_slave0_addr_slave1_data | r_slave1_data_slave1_data)}} & axi_r_user_i[1];




	/* write machine */
	parameter [2 : 0] W_IDLE = 3'b000, W_SLAVE0_ADDR = 3'b001, W_SLAVE1_ADDR = 3'b010, W_SLAVE0_DATA = 3'b011, W_SLAVE1_DATA = 3'b100, W_SLAVE0_RESP = 3'b101, W_SLAVE1_RESP = 3'b110;
	wire w_idle = w_state == W_IDLE, w_slave0_addr = w_state == W_SLAVE0_ADDR, w_slave1_addr = w_state == W_SLAVE1_ADDR, w_slave0_data = w_state == W_SLAVE0_DATA, w_slave1_data = w_state == W_SLAVE1_DATA, w_slave0_resp = w_state == W_SLAVE0_RESP, w_slave1_resp = w_state == W_SLAVE1_RESP;
	reg [2 : 0] w_state;
	wire slave0_aw_hs = axi_aw_ready_i[0] & m_axi_aw_valid_i;
	wire slave1_aw_hs = axi_aw_ready_i[1] & m_axi_aw_valid_i;

	wire slave0_w_done = axi_w_ready_i[0] & m_axi_w_valid_i & m_axi_w_last_i;
	wire slave1_w_done = axi_w_ready_i[1] & m_axi_w_valid_i & m_axi_w_last_i;
	wire slave0_b_hs   = axi_b_valid_i[0] & m_axi_b_ready_i;
	wire slave1_b_hs   = axi_b_valid_i[1] & m_axi_b_ready_i;
	always
		@(posedge clk) begin
			if(rst == 1'b1) begin
				w_state <= W_IDLE;
			end
			else begin
					case(w_state)
						W_IDLE: begin
							if(m_axi_aw_valid_i == 1'b1 && m_axi_aw_addr_i <= 32'h0200_ffff && m_axi_aw_addr_i >= 32'h0200_0000 ) begin
								w_state <= W_SLAVE0_ADDR;
							end
							else if(m_axi_aw_valid_i == 1'b1 ) begin
								w_state <= W_SLAVE1_ADDR;
							end
						end
						W_SLAVE0_ADDR: begin
							if(slave0_aw_hs) begin
								w_state <= W_SLAVE0_DATA;
							end
						end
						W_SLAVE1_ADDR: begin
							if(slave1_aw_hs) begin
								w_state <= W_SLAVE1_DATA;
							end
						end
						W_SLAVE0_DATA: begin
							if(slave0_w_done) begin
								w_state <= W_SLAVE0_RESP;
							end
						end
						W_SLAVE1_DATA: begin
							if(slave1_w_done) begin
								w_state <= W_SLAVE1_RESP;
							end
						end
						W_SLAVE0_RESP: begin
							if(slave0_b_hs) begin
								w_state <= W_IDLE;
							end
						end
						W_SLAVE1_RESP: begin
							if(slave1_b_hs) begin
								w_state <= W_IDLE;
							end
						end
					default: begin end
				endcase
			end
		end

	/* write address */
	assign	m_axi_aw_ready_o = (w_slave0_addr & axi_aw_ready_i[0])
							|  (w_slave1_addr & axi_aw_ready_i[1]);

	assign axi_aw_valid_o[0] = (w_slave0_addr & m_axi_aw_valid_i);
	assign axi_aw_addr_o[0] = ({AXI_ADDR_WIDTH{w_slave0_addr}} & m_axi_aw_addr_i);
	assign axi_aw_prot_o[0] = ({3{w_slave0_addr}} & m_axi_aw_prot_i);
	assign axi_aw_id_o[0] = ({AXI_ID_WIDTH{w_slave0_addr}} & m_axi_aw_id_i);
	assign axi_aw_user_o[0] = ({AXI_USER_WIDTH{w_slave0_addr}} & m_axi_aw_user_i);
	assign axi_aw_len_o[0] = ({8{w_slave0_addr}} & m_axi_aw_len_i);
	assign axi_aw_size_o[0] = ({3{w_slave0_addr}} & m_axi_aw_size_i);
	assign axi_aw_burst_o[0] = ({2{w_slave0_addr}} & m_axi_aw_burst_i);
	assign axi_aw_lock_o[0] = (w_slave0_addr & m_axi_aw_lock_i);
	assign axi_aw_cache_o[0] = ({4{w_slave0_addr}} & m_axi_aw_cache_i);
	assign axi_aw_qos_o[0] = ({4{w_slave0_addr}} & m_axi_aw_qos_i);
	
	assign axi_aw_valid_o[1] = (w_slave1_addr & m_axi_aw_valid_i);
	assign axi_aw_addr_o[1] = ({AXI_ADDR_WIDTH{w_slave1_addr}} & m_axi_aw_addr_i);
	assign axi_aw_prot_o[1] = ({3{w_slave1_addr}} & m_axi_aw_prot_i);
	assign axi_aw_id_o[1] = ({AXI_ID_WIDTH{w_slave1_addr}} & m_axi_aw_id_i);
	assign axi_aw_user_o[1] = ({AXI_USER_WIDTH{w_slave1_addr}} & m_axi_aw_user_i);
	assign axi_aw_len_o[1] = ({8{w_slave1_addr}} & m_axi_aw_len_i);
	assign axi_aw_size_o[1] = ({3{w_slave1_addr}} & m_axi_aw_size_i);
	assign axi_aw_burst_o[1] = ({2{w_slave1_addr}} & m_axi_aw_burst_i);
	assign axi_aw_lock_o[1] = (w_slave1_addr & m_axi_aw_lock_i);
	assign axi_aw_cache_o[1] = ({4{w_slave1_addr}} & m_axi_aw_cache_i);
	assign axi_aw_qos_o[1] = ({4{w_slave1_addr}} & m_axi_aw_qos_i);

	/* write data */
	assign m_axi_w_ready_o = (w_slave0_data & axi_w_ready_i[0])
						|	 (w_slave1_data & axi_w_ready_i[1]);

	assign axi_w_valid_o[0] = (w_slave0_data & m_axi_w_valid_i);
	assign axi_w_data_o[0] = ({AXI_DATA_WIDTH{w_slave0_data}} & m_axi_w_data_i);
	assign axi_w_strb_o[0] = ({8{w_slave0_data}} & m_axi_w_strb_i);
	assign axi_w_last_o[0] = (w_slave0_data & m_axi_w_last_i);

	assign axi_w_valid_o[1] = (w_slave1_data & m_axi_w_valid_i);
	assign axi_w_data_o[1] = ({AXI_DATA_WIDTH{w_slave1_data}} & m_axi_w_data_i);
	assign axi_w_strb_o[1] = ({8{w_slave1_data}} & m_axi_w_strb_i);
	assign axi_w_last_o[1] = (w_slave1_data & m_axi_w_last_i);

	/* resp */
	assign axi_b_ready_o[0] = (w_slave0_resp & m_axi_b_ready_i);
	assign axi_b_ready_o[1] = (w_slave1_resp & m_axi_b_ready_i);

	assign m_axi_b_valid_o = (w_slave0_resp & axi_b_valid_i[0])
						|	 (w_slave1_resp & axi_b_valid_i[1]);
	assign m_axi_b_resp_o = (w_slave0_resp & axi_b_resp_i[0])
						|	 (w_slave1_resp & axi_b_resp_i[1]);
	assign m_axi_b_id_o = ({AXI_ID_WIDTH{w_slave0_resp}} & axi_b_id_i[0])
						|	 ({AXI_ID_WIDTH{w_slave1_resp}} & axi_b_id_i[1]);
	assign m_axi_b_user_o = ({2{w_slave0_resp}} & axi_b_user_i[0])
						|	 ({2{w_slave1_resp}} & axi_b_user_i[1]);
endmodule


