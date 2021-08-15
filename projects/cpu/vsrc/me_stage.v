`include "defines.v"

module me_stage(
	input wire mem_ready,
	input wire me_mem_wena,
	input wire me_mem_rena,
	input wire [7 : 0] mem_byte_enable,
	input wire [1 : 0] mem_resp,		//TODO: check
	input wire [`REG_BUS] mem_data_read_i,
	input wire [`REG_BUS] me_alu_result,
	input wire [`REG_BUS] me_new_rs2_data,
	
	output wire mem_valid,
	output wire mem_req,
	output wire [`REG_BUS] mem_data_write,
	output wire [`REG_BUS] mem_data_addr,
	output wire [`REG_BUS] mem_data_read_o,
	output wire [1 : 0] mem_size,
	output wire stall_req
);
	
assign mem_data_addr = me_alu_result;	
assign mem_data_write = me_new_rs2_data;
assign mem_data_read_o = mem_data_read_i;
assign mem_valid = (me_mem_wena | me_mem_rena) & ~mem_ready;
assign mem_req = (me_mem_rena & `REQ_READ) | (me_mem_wena & `REQ_WRITE);
assign mem_size = ({2{(mem_byte_enable == 8'b0000_0001)}} & `SIZE_B)
				| ({2{(mem_byte_enable == 8'b0000_0011)}} & `SIZE_H)
				| ({2{(mem_byte_enable == 8'b0000_1111)}} & `SIZE_W)
				| ({2{(mem_byte_enable == 8'b1111_1111)}} & `SIZE_D);

assign stall_req =  mem_valid & ~mem_ready;
				

endmodule

