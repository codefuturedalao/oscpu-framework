`include "defines.v"

module if_stage(
  	input wire clk,
  	input wire rst,
	input wire [`REG_BUS] new_pc,
	input wire [1 : 0] stall,

	input wire inst_data_ok,
	input wire inst_addr_ok,
	input wire [`REG_BUS] inst_data,
  
	output wire [`REG_BUS] pc_minus_4,
	output wire if_req_valid,
	output wire if_req_op,
  	output wire [`REG_BUS] inst_addr,
  	output wire [`INST_BUS] inst,
	output wire inst_valid,
 	output wire stall_req
);

assign pc_minus_4 = pc;
reg [`REG_BUS] pc;
/* state machine */
parameter [2 : 0] ISSUE = 3'b000, WORK = 3'b001, W_ADDR = 3'b010, W_DATA = 3'b011, WAIT = 3'b100, W_OTHER = 3'b101;
reg [2 : 0] state;
wire state_issue = state == ISSUE, state_work = state == WORK, state_w_addr = state == W_ADDR, state_w_data = state == W_DATA, state_wait = state == WAIT, state_w_other = state == W_OTHER;
always
	@(posedge clk) begin
		if(rst == 1'b1) begin
			data_r <= `ZERO_WORD;
			data_r_2 <= `ZERO_WORD;
			data_r_2_valid <= 1'b0;
			state <= ISSUE;
			pc <= `PC_START_MINUS4;
		end	
		else begin
			case(state)
				ISSUE: begin				//first instruction
					if(addr_hs == 1'b1) begin
						state <= WORK;
						pc <= new_pc;
					end
				end
				WORK: begin
					if(addr_hs == 1'b1 & data_hs == 1'b1 & stall != `STALL_KEEP) begin
						state <= WORK;
						pc <= new_pc;
					end
					else if(addr_hs == 1'b1 & data_hs == 1'b1 & stall == `STALL_KEEP) begin
						state <= W_OTHER;	
						data_r <= inst_data;
					end
					else if(addr_hs == 1'b1 && data_hs == 1'b0) begin
						state <= W_DATA;
					end
					else if(addr_hs == 1'b0 && data_hs == 1'b1) begin
						state <= W_ADDR;
						data_r <= inst_data;
					end
					else if(addr_hs == 1'b0 && data_hs == 1'b0) begin
						state <= WAIT;
					end
				end
				W_DATA: begin
					if(data_hs == 1'b1 && stall != `STALL_KEEP) begin
						state <= WORK;
						pc <= new_pc;
					end
					else if(data_hs == 1'b1 && stall == `STALL_KEEP) begin
						state <= W_OTHER;
						data_r <= inst_data;
					end
				end
				W_ADDR: begin
					if(addr_hs == 1'b1 && stall != `STALL_KEEP) begin
						state <= WORK;
						pc <= new_pc;
					end
					else if(addr_hs == 1'b1 && stall == `STALL_KEEP) begin
						state <= W_OTHER;
					end
				end
				WAIT: begin
					//if(data_r_2_valid) data_r_2_valid <= 1'b0;
					if(addr_hs == 1'b1 && data_hs == 1'b1 && stall != `STALL_KEEP) begin
						state <= WORK;
						pc <= new_pc;
					end
					else if(addr_hs == 1'b1 && data_hs == 1'b1 && stall == `STALL_KEEP) begin
						state <= W_OTHER;
						data_r <= inst_data;
					end
					else if(addr_hs == 1'b0 && data_hs == 1'b1) begin
						state <= W_ADDR;
						data_r <= inst_data;
					end
					else if(addr_hs == 1'b1 && data_hs == 1'b0) begin
						state <= W_ADDR;
					end
				end
				W_OTHER: begin
					if(data_hs == 1'b1) begin		//shake again, the data is from next instruction
						data_r_2 <= inst_data;
						data_r_2_valid <= 1'b1;
					end
					if(stall != `STALL_KEEP && data_r_2_valid == 1'b0) begin
						state <= WORK;
						pc <= new_pc;
					end
					else if(stall != `STALL_KEEP & data_r_2_valid == 1'b1) begin
						state <= W_ADDR;
						pc <= new_pc;
						data_r <= data_r_2;
						data_r_2_valid <= 1'b0;
					end
				end
				default : state <= ISSUE;
			endcase
		end
	end

reg data_r_2_valid;
reg [`REG_BUS] data_r_2;
//reg addr_hs_r;
reg [`REG_BUS] data_r;
wire addr_hs = if_req_valid & inst_addr_ok;
wire data_hs = inst_data_ok;
//wire data_hs = addr_hs_r & data_ok;		//addr is ok, and next cycle data_ok
assign if_req_op = 1'b0;
assign if_req_valid = rst ? 1'b0 : 
					(state_issue)
				|	(state_work)
				|	(state_w_addr) 
				|	(state_wait);
assign inst_addr = new_pc;
assign stall_req = rst ? 1'b0 : (state_issue) 
				|  (state_work & (~addr_hs | ~data_hs)) 
				|  (state_w_addr & ~addr_hs) 
				|  (state_w_data & ~data_hs)
				|  (state_wait & (~addr_hs | ~data_hs));
wire [`REG_BUS] data = (state_w_other & inst_data_ok) ? inst_data : data_r;
assign inst = pc[2] ? data[63 : 32] : data[31 : 0];
assign inst_valid = rst ? 1'b0 : 
					(state_work & data_hs & addr_hs & stall != `STALL_KEEP)
				|	(state_w_addr & addr_hs & stall != `STALL_KEEP)
				|   (state_w_data & data_hs & stall != `STALL_KEEP)
				|	(state_wait   & data_hs & addr_hs & stall != `STALL_KEEP)
				|	(state_w_other & stall != `STALL_KEEP);

endmodule
