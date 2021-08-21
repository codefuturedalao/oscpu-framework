`include "defines.v"

module me_stage(
	input wire mem_rready,
	input wire mem_wready,
	input wire me_mem_wena,
	input wire me_mem_rena,
	input wire [7 : 0] mem_byte_enable,
	input wire [1 : 0] mem_rresp,		//TODO: check
	input wire [1 : 0] mem_wresp,		//TODO: check
	input wire [`REG_BUS] mem_data_read_i,
	input wire [`REG_BUS] me_alu_result,
	input wire [`REG_BUS] me_new_rs2_data,
	input wire me_exception_flag,
	input wire wb_exception_flag,
	
	output wire mem_rvalid,
	output wire mem_wvalid,
	output wire [`REG_BUS] mem_data_write,
	output wire [`REG_BUS] mem_data_raddr,
	output wire [`REG_BUS] mem_data_waddr,
	output wire [`REG_BUS] mem_data_read_o,
	output wire [1 : 0] mem_rsize,
	output wire [1 : 0] mem_wsize,
	output wire stall_req
);
	
assign mem_data_raddr = me_alu_result;	
assign mem_data_waddr = me_alu_result;	
assign mem_data_write = me_new_rs2_data;
assign mem_data_read_o = mem_data_read_i;
assign mem_rvalid =  me_mem_rena & ~mem_rready & ~me_exception_flag & ~wb_exception_flag;
assign mem_wvalid = me_mem_wena  & ~mem_wready & ~me_exception_flag & ~wb_exception_flag;
//assign mem_req = (me_mem_rena & `REQ_READ) | (me_mem_wena & `REQ_WRITE);
assign mem_rsize = ({2{(mem_byte_enable == 8'b0000_0001)}} & `SIZE_B)
				| ({2{(mem_byte_enable == 8'b0000_0011)}} & `SIZE_H)
				| ({2{(mem_byte_enable == 8'b0000_1111)}} & `SIZE_W)
				| ({2{(mem_byte_enable == 8'b1111_1111)}} & `SIZE_D);

assign mem_wsize = ({2{(mem_byte_enable == 8'b0000_0001)}} & `SIZE_B)
				| ({2{(mem_byte_enable == 8'b0000_0011)}} & `SIZE_H)
				| ({2{(mem_byte_enable == 8'b0000_1111)}} & `SIZE_W)
				| ({2{(mem_byte_enable == 8'b1111_1111)}} & `SIZE_D);

assign stall_req =  (mem_rvalid & ~mem_rready) | (mem_wvalid & ~mem_wready);
				

endmodule

