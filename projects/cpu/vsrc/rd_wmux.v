`include "defines.v"
/* wb stage */
module rd_wmux(
	input wire [`REG_BUS] alu_result,
	input wire [`REG_BUS] mem_data,
	input wire [`REG_BUS] csr_data,
	input wire mem_to_reg,
	input wire mem_ext_un,
	input wire [7 : 0] byte_enable,		//useless
	input wire csr_rena,
	input wire rd_wena_i,
	input wire exception_flag,
	
	output reg [`REG_BUS] rd_wdata,
	output reg rd_wena_o
);

	//wire [`REG_BUS] mask;
	wire [`REG_BUS] mem_data_new;
	/*assign mask = { {8{byte_enable[7]}},
                {8{byte_enable[6]}},
                {8{byte_enable[5]}},
                {8{byte_enable[4]}},
                {8{byte_enable[3]}},
                {8{byte_enable[2]}},
                {8{byte_enable[1]}},
                {8{byte_enable[0]}}};
	
	
	wire [5 : 0] shift_bit = {alu_result[2:0], 3'b000};
	*/
	assign mem_data_new = mem_data;

	//load or other
	assign rd_wdata = csr_rena   ? csr_data :
					  mem_to_reg ? 
							({64{byte_enable == 8'b0000_0001 & mem_ext_un}} & {56'b0, mem_data_new[7 : 0]} 
							|{64{byte_enable == 8'b0000_0011 & mem_ext_un}} & {48'b0, mem_data_new[15 : 0]}
							|{64{byte_enable == 8'b0000_1111 & mem_ext_un}} & {32'b0, mem_data_new[31 : 0]}
							|{64{byte_enable == 8'b0000_0001 & ~mem_ext_un}} & {{56{mem_data_new[7]}}, mem_data_new[7:0]}
							|{64{byte_enable == 8'b0000_0011 & ~mem_ext_un}} & {{48{mem_data_new[15]}}, mem_data_new[15:0]}
							|{64{byte_enable == 8'b0000_1111 & ~mem_ext_un}} & {{32{mem_data_new[31]}}, mem_data_new[31:0]}
							|{64{byte_enable == 8'b1111_1111}} & {mem_data_new[63 : 0]})	
				 	 : alu_result;
	
	assign rd_wena_o = ~exception_flag & rd_wena_i;
endmodule
