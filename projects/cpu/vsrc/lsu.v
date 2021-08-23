`include "defines.v"

module lsu(
	input wire clk,
	input wire rst,
	input wire ex_stall,
	input wire me_stall,

	input wire [`REG_BUS] mem_data_read_i,
	input wire [7 : 0] ex_wstrb,
	input wire [`REG_BUS] ex_alu_result,
	input wire [`REG_BUS] ex_mem_wdata,
	input wire me_control_transfer,
	input wire ex_exception_flag,
	input wire me_exception_flag,
	input wire wb_exception_flag,

	input wire ex_mem_rena,
	input wire ex_mem_wena,
	
	input wire addr_ok,
	input wire data_ok,
			

	output wire ex_stall_req,
	output wire me_stall_req,
	output wire me_req_valid,
	output wire me_req_op,
	output wire me_addr,
	output wire [7 : 0] me_wstrb,
	output wire	[`REG_BUS] me_wdata,
	output wire [`REG_BUS] mem_data_read_o
);

assign mem_data_read_o = mem_data_read_i;

reg [`REG_BUS] me_wdata_r;
reg [`REG_BUS] me_addr_r;
wire addr_hs = me_req_valid & addr_ok;
assign me_req_valid = (state_idle & (~me_control_transfer & ~ex_exception_flag & ~me_exception_flag & ~wb_exception_flag & (ex_mem_rena | ex_mem_wena)))
					| (state_w_data &  (~me_control_transfer & ~ex_exception_flag & ~me_exception_flag & ~wb_exception_flag & (ex_mem_rena | ex_mem_wena)))
					| (state_w_addr & 1'b1)
					| (state_w_addr_data & 1'b1)
					| (state_w_data_addr_ok & 1'b0);

assign me_req_op = (ex_mem_wena & 1'b1) | (ex_mem_rena & 1'b0);

assign me_addr = {64{state_idle | state_w_data}} & ex_alu_result 
				|{64{state_w_addr | state_w_addr_data}} & me_addr_r;

assign me_wstrb = ex_wstrb;

assign me_wdata = {64{state_idle | state_w_data}} & ex_mem_wdata
				|{64{state_w_addr | state_w_addr_data}} & me_wdata_r;

assign ex_stall_req = (state_idle & me_req_valid & ~addr_ok)
					| (state_w_data & me_req_valid & ~addr_ok)
					| (state_w_addr & me_req_valid & ~addr_ok)
					| (state_w_addr_data & me_req_valid & ~addr_ok);

assign me_stall_req = (state_w_data & ~data_ok)
					| (state_w_addr_data & ~data_ok)
					| (state_w_data_addr_ok & ~data_ok);


/* state machine */

parameter [2 : 0] IDLE = 3'b000, W_DATA = 3'b001, W_ADDR = 3'b010, W_ADDR_DATA = 3'b011, W_DATA_ADDR_OK = 3'b100;
wire state_idle = lsu_state == IDLE, state_w_data = lsu_state == W_DATA, state_w_addr = lsu_state == W_ADDR, state_w_addr_data = lsu_state == W_ADDR_DATA, state_w_data_addr_ok = lsu_state == W_DATA_ADDR_OK;
reg [2 : 0] lsu_state;
always
	@(posedge clk) begin
		if(rst == 1'b1 | ex_stall == `STALL_ZERO | me_stall == `STALL_ZERO) begin
			lsu_state <= IDLE;
			me_wdata_r <= `ZERO_WORD;	
			me_addr_r <= `ZERO_WORD;	
		end
		else begin		//ADD STALL constriction
			case(lsu_state)
				IDLE: begin
					if(addr_hs && me_stall == `STALL_NEXT) begin
						lsu_state <= W_DATA;
					end
					else if(me_req_valid == 1'b1 && addr_ok == 1'b0) begin
						lsu_state <= W_ADDR;
						me_wdata_r <= ex_mem_wdata;
						me_addr_r <= ex_alu_result;
					end
				end
				W_DATA: begin
					if(addr_hs && data_ok == 1'b1) begin
						lsu_state <= W_DATA;			//loop
					end
					else if(addr_hs && data_ok == 1'b0) begin
						lsu_state <= W_DATA_ADDR_OK;
					end
					else if(me_req_valid == 1'b1 && addr_ok == 1'b0 && data_ok == 1'b0) begin
						lsu_state <= W_ADDR_DATA;
						me_wdata_r <= ex_mem_wdata;
						me_addr_r <= ex_alu_result;
					end
					else if(me_req_valid == 1'b1 && addr_ok == 1'b0 && data_ok == 1'b1) begin
						lsu_state <= W_ADDR;
						me_wdata_r <= ex_mem_wdata;
						me_addr_r <= ex_alu_result;
					end
					else if(me_req_valid == 1'b0 && addr_ok == 1'b0 && data_ok == 1'b0) begin
						lsu_state <= W_DATA;
					end
					else if(me_req_valid == 1'b0 && addr_ok == 1'b0 && data_ok == 1'b1) begin
						lsu_state <= IDLE;
					end
				end
				W_ADDR: begin
					if(addr_hs == 1'b1) begin
						lsu_state <= W_DATA;
					end
				end
				W_ADDR_DATA: begin
					if(addr_hs && data_ok == 1'b1) begin
						lsu_state <= W_DATA;
					end
					else if(addr_hs && data_ok == 1'b0) begin
						lsu_state <= W_DATA_ADDR_OK;
					end
					else if(addr_hs == 1'b0 && data_ok == 1'b1) begin
						lsu_state <= W_ADDR;
					end
				end
				W_DATA_ADDR_OK: begin
					if(data_ok == 1'b1) begin
						lsu_state <= W_DATA;
					end
				end
				default : lsu_state <= IDLE;
			endcase
		end
	end


endmodule
