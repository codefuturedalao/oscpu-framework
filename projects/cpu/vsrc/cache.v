`include "defines.v"

module cache #(
	parameter INDEX_LEN = 8,
	parameter OFFSET_LEN = 4,
	parameter TAG_LEN = 52,
	parameter WAY_NUM = 2,
	parameter BLOCK_SIZE = 1 << OFFSET_LEN,		//16 bytes
	parameter DATA_LEN = 64,
	parameter STRB_LEN = DATA_LEN / 8 
	//parameter  
)
(
	input wire clk,
	input wire rst,

	input wire req_valid,
	input wire req_op,
	input wire [INDEX_LEN - 1 : 0] index,
	input wire [TAG_LEN - 1 : 0] tag,
	input wire [OFFSET_LEN - 1 : 0] offset,
	input wire [STRB_LEN - 1 : 0] wstrb,
	input wire [DATA_LEN - 1 : 0] wdata,
	output wire addr_ok,
	output wire data_ok,
	output wire [DATA_LEN - 1 : 0] rdata,

	output wire raxi_valid,
	output wire [2 : 0] raxi_size,
	output wire [`REG_BUS] raxi_addr,		//TODO physical address's width may not be 64 //	input wire raxi_ready
	input wire raxi_dvalid,
	input wire raxi_dlast,
	input wire [DATA_LEN - 1 : 0] raxi_data,
	output wire waxi_valid,
	output wire waxi_size,
	output wire [`REG_BUS] waxi_addr,
//	output wire waxi_strb,
	output wire [BLOCK_LEN - 1 : 0] waxi_data,		//TODO BLOCK_LEN define
	input wire waxi_ready
);
	parameter SET_NUM = 1 << INDEX_LEN;
	parameter DATA_SIZE = DATA_LEN / 8;
	parameter BANK_NUM_PER_WAY = BLOCK_SIZE  / DATA_SIZE;
	parameter BANK_NUM = BANK_NUM_PER_WAY * WAY_NUM;

	/*		RAM		*/
	//Data table
	generate
			for(genvar i = 0;i < BANK_NUM ;i = i + 1) begin: DataTable
				singlePortRam #(DATA_LEN, SET_NUM) Bank(.clk(clk), .rst(rst), .addr(data_addr[i]), .cs_n(data_cs[i]), .we(data_we[i]), .din(data_din[i]), .dout(data_dout[i]));
			end
	endgenerate
	//tag, v table
	generate
			for(genvar i = 0;i < WAY_NUM ;i = i + 1) begin: TagTable
				singlePortRam #(TAG_LEN + 1, SET_NUM) Bank(.clk(clk), .rst(rst), .addr(tag_addr[i]), .cs_n(tag_cs[i]), .we(tag_we[i]), .din(tag_din[i]), .dout(tag_dout[i]));
			end
	endgenerate
	//d table
	generate
			for(genvar i = 0;i < WAY_NUM ;i = i + 1) begin: DTable
				singlePortRam #(1, SET_NUM) Bank(.clk(clk), .rst(rst), .addr(dirty_addr[i]), .cs_n(dirty_cs[i]), .we(dirty_we[i]), .din(dirty_din[i]), .dout(dirty_dout[i]));
			end
	endgenerate

	/*	input signal	*/
	//wire conflict = (req_valid == 1'b1 && req_op == 1'b0 && whit && tag == request_buffer_tag && index == request_buffer_index && offset[3] == request_buffer_offset[3]) | (req_valid == 1'b1 && req_op == 1'b0 && w_state_write && write_buffer_offset[3] == offset[3]);
	//wire conflict = (req_valid == 1'b1 && req_op == 1'b0 && whit && tag == request_buffer_tag && index == request_buffer_index && offset[3] == request_buffer_offset[3]) | (req_valid == 1'b1 && w_state_write && write_buffer_offset[3] == offset[3]);
	wire conflict = (req_valid == 1'b1 && whit && tag == request_buffer_tag && index == request_buffer_index && offset[3] == request_buffer_offset[3]) | (req_valid == 1'b1 && w_state_write && write_buffer_offset[3] == offset[3]);
	wire req_rvalid = req_valid & (req_op == 1'b0) & ~conflict;
	wire req_wvalid = req_valid & (req_op == 1'b1) & ~conflict;	//no need to test conflict
	wire raxi_done = raxi_dvalid & raxi_dlast;
	


	/*  state machine  	*/
	parameter [2 : 0] M_STATE_IDLE = 3'b000, M_STATE_LOOKUP = 3'b001, M_STATE_MISS = 3'b010,
					  M_STATE_REPLACE = 3'b011, M_STATE_REFILL = 3'b100;	
	parameter W_STATE_IDLE = 1'b0, W_STATE_WRITE = 1'b1;

	wire m_state_idle = m_state == M_STATE_IDLE, m_state_lookup = m_state == M_STATE_LOOKUP, m_state_miss = m_state == M_STATE_MISS, m_state_replace = m_state == M_STATE_REPLACE, m_state_refill = m_state == M_STATE_REFILL;
	wire w_state_idle = w_state == W_STATE_IDLE, w_state_write = w_state == W_STATE_WRITE;
	reg [2 : 0] m_state;
	reg w_state;
	always
		@(posedge clk) begin
			if(rst == 1'b1) begin
				m_state <= M_STATE_IDLE;	
			end
			else begin
				case(m_state)
					M_STATE_IDLE: begin
						if(req_valid == 1'b1 && conflict == 1'b0) begin		//req is valid and no conflicts
							m_state <= M_STATE_LOOKUP;
						end
						//else idle
					end
					M_STATE_LOOKUP: begin
						if(hit && (req_valid == 1'b0 | conflict == 1'b1)) begin
							m_state <= M_STATE_IDLE;
						end
						else if(hit == 1'b0) begin
							m_state <= M_STATE_MISS;	
						end
						//else if(hit && req_valid == 1'b1 && conflict == 1'b0) keep lookup
					end
					M_STATE_MISS: begin
						if(waxi_ready == 1'b1) begin		
							m_state <= M_STATE_REPLACE;
						end
					end
					M_STATE_REPLACE: begin
		//				if(raxi_ready == 1'b1) begin
		//					m_state <= M_STATE_REFILL;
		//				end
						m_state <= M_STATE_REFILL;	//keep 1 cycle
					end
					M_STATE_REFILL:	
						if(counter == WAY_NUM) begin
							m_state <= M_STATE_IDLE;
						end
					default: begin end
				endcase
			end
		end

	always
		@(posedge clk) begin
			if(rst == 1'b1) begin
				w_state <= W_STATE_IDLE;
			end
			else begin
				case(w_state)
					W_STATE_IDLE: begin
						if(whit) begin
							w_state <= W_STATE_WRITE;
						end	
					end
					W_STATE_WRITE: begin
						//if(~(whit && w_state_lookup)) begin
						if(~whit) begin
							w_state <= W_STATE_IDLE;
						end
					end
				endcase
			end
		end

	/* Main State Transaction */
	//parameter BANK_NUM_PER_WAY
	//TODO: use parameter to generate 
	parameter ADDR_WIDTH = $clog2(SET_NUM);		//same as INDEX_LEN
	wire [BANK_NUM - 1 : 0] data_cs;		
	wire [BANK_NUM - 1 : 0] data_we;		
	wire [ADDR_WIDTH - 1 : 0] data_addr [BANK_NUM - 1 : 0];		
	wire [DATA_LEN - 1 : 0] data_din [BANK_NUM - 1 : 0];		
	wire [DATA_LEN - 1 : 0] data_dout [BANK_NUM - 1 : 0];		
	generate
			for(genvar i = 0;i < BANK_NUM; i = i + 1) begin: idle_data_cs
				assign data_cs[i] = ((m_state_lookup | m_state_idle) && (req_rvalid | req_wvalid) && (offset[3] == (i & 1'b1))) 
				| (w_state_write & (write_buffer_offset[3] == (i & 1'b1)) & write_buffer_wayhit[(i & 2'b10) >> 1] == 1'b1)
				| (m_state_refill & raxi_dvalid & (counter == (i & 1'b1)) & (miss_buffer_replace_way == ((i & 2'b10) >> 1))) ? `CHIP_EN : `CHIP_DI;	

			end
	endgenerate
/*
		assign data_cs[2'b00] = ((m_state_lookup | m_state_idle) && (req_rvalid | req_wvalid) && offset[3] == 1'b0) | (m_state_lookup & write_buffer_offset[3] == 1'b0 & write_buffer_wayhit[0] == 1'b1) ? `CHIP_EN : `CHIP_DI;	
		assign data_cs[2'b01] = ((m_state_lookup | m_state_idle) && (req_rvalid | req_wvalid) && offset[3] == 1'b1)  | (m_state_lookup & write_buffer_offset[3] == 1'b1 & write_buffer_wayhit[0] == 1'b1) ? `CHIP_EN : `CHIP_DI;	
		assign data_cs[2'b10] = ((m_state_lookup | m_state_idle) && (req_rvalid | req_wvalid) && offset[3] == 1'b0)  | (m_state_lookup & write_buffer_offset[3] == 1'b0 & write_buffer_wayhit[1] == 1'b1) ? `CHIP_EN : `CHIP_DI;	
		assign data_cs[2'b11] = ((m_state_lookup | m_state_idle) && (req_rvalid | req_wvalid) && offset[3] == 1'b1)  | (m_state_lookup & write_buffer_offset[3] == 1'b1 & write_buffer_wayhit[1] == 1'b1) ? `CHIP_EN : `CHIP_DI;	
	
*/
	//assign data_we = m_state_lookup{BANK_NUM{1'b0}};		//all read signal
	generate
			for(genvar i = 0;i < BANK_NUM; i = i + 1) begin: idle_data_we
				assign data_we[i] = (w_state_write & (write_buffer_offset[3] == (i & 1'b1)) & write_buffer_wayhit[(i & 2'b10) >> 1] == 1'b1) & 1'b1 
								 |  (m_state_refill & raxi_dvalid & (counter == (i & 1'b1)) & (miss_buffer_replace_way == ((i & 2'b10) >> 1))) & 1'b1;
			end
	endgenerate

	generate
			for(genvar i = 0;i < BANK_NUM; i = i + 1) begin: idle_data_addr
				assign data_addr[i] = ({INDEX_LEN{((m_state_lookup | m_state_idle) && (req_rvalid | req_wvalid) && (offset[3] == (i & 1'b1)))}} & index) 
								| ({INDEX_LEN{(w_state_write & (write_buffer_offset[3] == (i & 1'b1)) & write_buffer_wayhit[(i & 2'b10) >> 1] == 1'b1)}} & write_buffer_index)
								| ({INDEX_LEN{(m_state_refill & raxi_dvalid & (counter == (i & 1'b1)) & (miss_buffer_replace_way == ((i & 2'b10) >> 1)))}} & miss_buffer_replace_index);

				assign data_din[i] = ({DATA_LEN{(w_state_write & (write_buffer_offset[3] == (i & 1'b1)) & write_buffer_wayhit[(i & 2'b10) >> 1] == 1'b1)}} & write_buffer_wdata)
								| ({DATA_LEN{(m_state_refill & raxi_dvalid & (counter == (i & 1'b1)) & miss_buffer_replace_way == ((i & 2'b10) >> 1) & (request_buffer_offset[3] != (i & 1'b1)))}} & raxi_data)
								| ({DATA_LEN{(m_state_refill & raxi_dvalid & (counter == (i & 1'b1)) & miss_buffer_replace_way == ((i & 2'b10) >> 1) & (request_buffer_offset[3] == (i & 1'b1)))}} & request_buffer_wdata);
			end
	endgenerate
	
	
	wire [WAY_NUM - 1 : 0] tag_cs;
	wire [WAY_NUM - 1 : 0] tag_we;		
	wire [ADDR_WIDTH - 1 : 0] tag_addr [WAY_NUM - 1 : 0];		
	wire [TAG_LEN + 1 - 1 : 0] tag_din [WAY_NUM - 1 : 0];		
	wire [TAG_LEN + 1 - 1 : 0] tag_dout [WAY_NUM - 1 : 0];		
	generate
			for(genvar i = 0;i < WAY_NUM; i = i + 1) begin: idle_tag_cs
				assign tag_cs[i] = ((m_state_lookup | m_state_idle) && (req_rvalid | req_wvalid)) 
								|  ((m_state_refill & raxi_dvalid & miss_buffer_replace_way == i )) 
					? `CHIP_EN : `CHIP_DI;
			end
	endgenerate

	generate
			for(genvar i = 0;i < WAY_NUM; i = i + 1) begin: idle_tag_we
				assign tag_we[i] = (m_state_refill & raxi_dvalid & miss_buffer_replace_way == i);
			end
	endgenerate
	//assign tag_we = {WAY_NUM{1'b0}};		//read the tag, write whe refill

	generate
			for(genvar i = 0;i < WAY_NUM; i = i + 1) begin: idle_tag_addr
				assign tag_addr[i] = (m_state_refill & raxi_dvalid & miss_buffer_replace_way == i) ? miss_buffer_replace_index : index;
				assign tag_din[i] = {1'b1, request_buffer_tag};
			end
	endgenerate
	
	
	wire [WAY_NUM - 1 : 0] dirty_cs;
	wire [WAY_NUM - 1 : 0] dirty_we;		
	wire [ADDR_WIDTH - 1 : 0] dirty_addr [WAY_NUM - 1 : 0];		
	wire [1 - 1 : 0] dirty_din [WAY_NUM - 1 : 0];		
	wire [1 - 1 : 0] dirty_dout [WAY_NUM - 1 : 0];		
	generate
			for(genvar i = 0;i < WAY_NUM; i = i + 1) begin: idle_dirty_cs
				//assign dirty_cs[i] = ((m_state_lookup | m_state_idle) && (req_rvalid | req_wvalid)) | (w_state_write && write_buffer_wayhit[i & 1'b1] == 1'b1) ? `CHIP_EN : `CHIP_DI;
				assign dirty_cs[i] = (w_state_write && write_buffer_wayhit[i & 1'b1] == 1'b1) 
								|	 (m_state_refill & raxi_dvalid & miss_buffer_replace_way == i)? `CHIP_EN : `CHIP_DI;		//don't read in the idle and lookup stage
			end
	endgenerate

	//assign dirty_we = {WAY_NUM{1'b0}};		//read the tag
	generate
			for(genvar i = 0;i < WAY_NUM; i = i + 1) begin: idle_dirty_we
				assign dirty_we[i] = (w_state_write & write_buffer_wayhit[(i & 1'b1)] == 1'b1) & 1'b1
									|(m_state_refill & raxi_dvalid & miss_buffer_replace_way == i) & 1'b1;
			end
	endgenerate

	generate
			for(genvar i = 0;i < WAY_NUM; i = i + 1) begin: idle_dirty_addr
				assign dirty_addr[i] = w_state_write ? write_buffer_index : ((m_state_refill & raxi_dvalid & miss_buffer_replace_way == i) ? miss_buffer_replace_index : index);		
				assign dirty_din[i] = (w_state_write | (m_state_refill & raxi_dvalid & miss_buffer_replace_way == i && request_buffer_op == 1'b1)) ? 1'b1 : 1'b0;		//only write
			end
	endgenerate


	reg [TAG_LEN - 1 : 0] request_buffer_tag;
	reg request_buffer_op;
	reg [STRB_LEN - 1 : 0] request_buffer_strb;
	reg [DATA_LEN - 1 : 0] request_buffer_data;
	reg [OFFSET_LEN - 1 : 0] request_buffer_offset;
	reg [INDEX_LEN - 1 : 0] request_buffer_index;
	always
		@(posedge clk) begin
			if(rst == 1'b1) begin
				request_buffer_tag <= {TAG_LEN{1'b0}};
				request_buffer_op <= 1'b0;
				request_buffer_strb <= {STRB_LEN{1'b0}};
				request_buffer_data <= {DATA_LEN{1'b0}};
				request_buffer_offset <= {OFFSET_LEN{1'b0}};
				request_buffer_index <= {INDEX_LEN{1'b0}};
			end
			else begin
				if(((m_state_lookup && hit) | m_state_idle) && (req_rvalid | req_wvalid)) begin		//what if miss
					request_buffer_tag <= tag;
					request_buffer_op <= req_op;
					request_buffer_strb <= (wstrb << offset[2 : 0]);
					request_buffer_data <= (wdata << ({offset[2 : 0], 3'b000}));
					request_buffer_offset <= offset;
					request_buffer_index <= index;
				end
			end
		end

	wire [DATA_LEN - 1 : 0] request_buffer_wdata;
	generate
		for(genvar i = 0; i < STRB_LEN; i++) begin
			assign request_buffer_wdata[i * 8 +: 8] = (request_buffer_op & request_buffer_strb[i]) == 1 ? request_buffer_data[i * 8 +: 8] : raxi_data[i * 8 +: 8];
		end
	endgenerate

	// look up stage
	parameter BLOCK_LEN = BLOCK_SIZE << 3;
	wire [WAY_NUM - 1 : 0] way_hit;
	wire [BLOCK_LEN - 1 : 0] way_data [WAY_NUM - 1 : 0];
	wire hit = |way_hit;
	wire whit = hit & request_buffer_op;
	wire rhit = hit & ~request_buffer_op;
	generate
			for(genvar i = 0;i < WAY_NUM; i = i + 1) begin: lookup_hit
				assign way_hit[i] = (m_state_lookup && tag_dout[i][0 +: TAG_LEN] == request_buffer_tag && (tag_dout[i][TAG_LEN] == 1'b1));
				assign way_data[i] = {data_dout[(i << 1) + 1], data_dout[i << 1]};
			end
	endgenerate

	//read hit, no other request, go to idle
	/*wire [DATA_LEN - 1 : 0] hit_data = {64{way_hit[0]}} & (way_data[offset[3] * 64 +: 64])
				 					 | {64{way_hit[1]}} & (way_data[offset[3] * 64 +: 64]);
*/
	wire [DATA_LEN - 1 : 0] hit_data = {64{way_hit[0]}} & (data_dout[{1'b0, request_buffer_offset[3]}])
				 					 | {64{way_hit[1]}} & (data_dout[{1'b1, request_buffer_offset[3]}]);

	//read hit and request valid, still lookup
	//write hit, store info in write buffer
	wire [2 : 0] seed_data = 8'b10010101;
	wire [31 : 0] lfsr_data;
	lfsr #(.NUM_BITS(32)) Lfsr(clk, ~rst, .i_Seed_DV(1'b0), .i_Seed_Data(seed_data), .o_LFSR_Data(lfsr_data), .o_LFSR_Done());
	wire [1 : 0] way_sel = (^lfsr_data) ? 2'b01 : 2'b10;
	//miss
	wire [BLOCK_LEN - 1 : 0] replace_data = {BLOCK_LEN{way_sel[0]}} & (way_data[0])
											| {BLOCK_LEN{way_sel[1]}} & (way_data[1]);
	wire [TAG_LEN + 1 - 1 : 0] replace_tag = {TAG_LEN{way_sel[0]}} & tag_dout[0]
										|  {TAG_LEN{way_sel[1]}} & tag_dout[1];
	wire [INDEX_LEN - 1 : 0] replace_index = request_buffer_index;
	
	parameter WAY_LEN = $clog2(WAY_NUM);
	reg [WAY_LEN - 1 : 0] miss_buffer_replace_way;
	reg [BLOCK_LEN - 1 : 0] miss_buffer_replace_data;
	reg [TAG_LEN +1 - 1 : 0] miss_buffer_replace_tag;
	reg [INDEX_LEN - 1 : 0] miss_buffer_replace_index;
	reg [DATA_LEN - 1 : 0] miss_buffer_rdata;
	always
		@(posedge clk) begin
			if(rst == 1'b1) begin
				miss_buffer_replace_way <= {WAY_LEN{1'b0}};
				miss_buffer_replace_data <= {BLOCK_LEN{1'b0}};
				miss_buffer_replace_tag <= {TAG_LEN + 1{1'b0}};
				miss_buffer_replace_index <= {INDEX_LEN{1'b0}};
			end
			else if(hit == 1'b0 && m_state_lookup == 1'b1) begin
				miss_buffer_replace_way <= way_sel;
				miss_buffer_replace_data <= replace_data;
				miss_buffer_replace_tag <=  replace_tag;
				miss_buffer_replace_index <= replace_index;
			end
		end
	//replace
	assign waxi_valid = m_state_replace & miss_buffer_replace_tag[TAG_LEN];
	assign waxi_data = miss_buffer_replace_data;
	assign waxi_size = `SIZE_L;
	assign waxi_addr = {miss_buffer_replace_tag[TAG_LEN - 1 : 0], miss_buffer_replace_index, {OFFSET_LEN{1'b0}}};
	//assign waxi_size = ;
	//assign waxi_strb = ;
	//refill
	//assign raxi_valid = m_state_refill & ~raxi_dlast;
	assign raxi_valid = m_state_refill & ~raxi_dlast & (counter != WAY_NUM);
	assign raxi_size = `SIZE_L;
	assign raxi_addr = {request_buffer_tag, request_buffer_index, {OFFSET_LEN{1'b0}}};

	reg [2 : 0]  counter;
    wire counter_rst = rst | ~m_state_refill;		//
    wire counter_incr_en    = (counter != BANK_NUM_PER_WAY) & (raxi_dvalid); //incre in every data transfer
    always @(posedge clk) begin
        if (counter_rst) begin
            counter <= 0;
        end
        else if (counter_incr_en) begin
            counter <= counter + 1;
        end
    end
	
	// get the need data 
	always 
		@(posedge clk) begin
			if(rst == 1'b1) begin
				miss_buffer_rdata <= {DATA_LEN{1'b0}};
			end
			else if((raxi_dvalid & m_state_refill) && counter == request_buffer_offset[3]) begin
				miss_buffer_rdata <= raxi_data;	
			end
		end
	//

	/* Write State Transaction */
	//parameter WAY_LEN = $clog2(WAY_NUM);
	reg [INDEX_LEN - 1 : 0] write_buffer_index;
	reg [STRB_LEN - 1 : 0] write_buffer_strb;
	reg [DATA_LEN - 1 : 0] write_buffer_data;
	reg [DATA_LEN - 1 : 0] write_buffer_rdata;
	reg [WAY_NUM - 1 : 0] write_buffer_wayhit;
	reg [OFFSET_LEN - 1 : 0] write_buffer_offset;
	
	always
		@(posedge clk) begin
			if(rst == 1'b1) begin
					write_buffer_index <= {INDEX_LEN{1'b0}};
					write_buffer_strb <= {STRB_LEN{1'b0}};
					write_buffer_data <= {DATA_LEN{1'b0}};
					write_buffer_rdata <= {DATA_LEN{1'b0}};	
					write_buffer_wayhit <= {WAY_NUM{1'b0}};
					write_buffer_offset <= {OFFSET_LEN{1'b0}};
			end	
			else begin
				if(whit) begin
					write_buffer_index <= request_buffer_index;
					write_buffer_strb <= request_buffer_strb;
					write_buffer_data <= request_buffer_data;
					write_buffer_rdata <= hit_data;	
					write_buffer_wayhit <= way_hit;
					write_buffer_offset <= request_buffer_offset;
				end
			end
		end
		
	wire [DATA_LEN - 1 : 0] write_buffer_wdata;
	generate
		for(genvar i = 0; i < STRB_LEN; i++) begin
			assign write_buffer_wdata[i * 8 +: 8] = write_buffer_strb[i] == 1 ? write_buffer_data[i * 8 +: 8] : write_buffer_rdata[i * 8 +: 8];
		end
	endgenerate


	/*  output signal   */
	assign addr_ok = (m_state_idle & conflict == 1'b0) | (m_state_lookup && hit && req_valid == 1'b1 && conflict == 1'b0);
	assign data_ok = (m_state_lookup & hit) | (m_state_lookup & (request_buffer_op == 1'b1)) | (m_state_refill & counter == request_buffer_offset[3] + 1 & request_buffer_op == 1'b0);
	//assign rdata = {64{rhit}} & hit_data | miss_buffer_rdata;		//TODO
	assign rdata = rhit ?  hit_data : miss_buffer_rdata;		//cannot keep

	



endmodule
	
