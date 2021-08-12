`include "defines.v"
/* wb stage */
module rd_wmux(
	input wire [`REG_BUS] alu_result,
	input wire [`REG_BUS] mem_data,
	input wire [`REG_BUS] csr_data,
	input wire mem_to_reg,
	input wire mem_ext_un,
	input wire [7 : 0] byte_enable,
	input wire csr_rena,
	
	output reg [`REG_BUS] rd_wdata
);

	//TODO: figure it out that should use same mask signal	
	wire [`REG_BUS] mask;
	//wire [7 : 0] byte_en_new;
	wire [`REG_BUS] mem_data_tmp;
	wire [`REG_BUS] mem_data_new;
	//wire ext_bit;
	//assign byte_en_new = byte_enable << alu_result[2:0];
	/*assign mask = { {8{byte_en_new[7]}},
                {8{byte_en_new[6]}},
                {8{byte_en_new[5]}},
                {8{byte_en_new[4]}},
                {8{byte_en_new[3]}},
                {8{byte_en_new[2]}},
                {8{byte_en_new[1]}},
                {8{byte_en_new[0]}}};
	*/
	assign mask = { {8{byte_enable[7]}},
                {8{byte_enable[6]}},
                {8{byte_enable[5]}},
                {8{byte_enable[4]}},
                {8{byte_enable[3]}},
                {8{byte_enable[2]}},
                {8{byte_enable[1]}},
                {8{byte_enable[0]}}};
	
	
	wire [5 : 0] shift_bit = {alu_result[2:0], 3'b000};
	assign mem_data_tmp = mem_data  >> shift_bit;
	assign mem_data_new = (mem_data & mask);
	//assign mem_data_new = (mem_data & mask) >> shift_bit;
	
	//load or other
	always
		@(*) begin
			if(csr_rena == 1'b1) begin
				rd_wdata = csr_data;
			end
			else if(mem_to_reg == 1'b1) begin		//load
					case(byte_enable) 
						8'b0000_0001:	begin
							if(mem_ext_un == 1'b1) begin
								rd_wdata = {56'b0, mem_data_new[7:0]};
							end
							else begin
								rd_wdata = {{56{mem_data_new[7]}}, mem_data_new[7:0]};
							end
						end
						8'b0000_0011:	begin
							if(mem_ext_un == 1'b1) begin
								rd_wdata = {48'b0, mem_data_new[15:0]};
							end
							else begin
								rd_wdata = {{48{mem_data_new[15]}}, mem_data_new[15:0]};
							end
						end
						8'b0000_1111:	begin
							if(mem_ext_un == 1'b1) begin
								rd_wdata = {32'b0, mem_data_new[31:0]};
							end
							else begin
								rd_wdata = {{32{mem_data_new[31]}}, mem_data_new[31:0]};
							end
						end
						8'b1111_1111:	begin
								rd_wdata = mem_data_new;
						end
						default: begin
								rd_wdata = `ZERO_WORD;
						end
					endcase	
			end
			else begin		//other
				rd_wdata = alu_result;
			end
		end	
	

endmodule
