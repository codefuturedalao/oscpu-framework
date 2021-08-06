`include "defines.v"
module csr(
	input wire clk,
	input wire rst,
	input wire [11 : 0] csr_addr,
	input wire csr_rena,
	input wire csr_wena,
	input wire [1 : 0] csr_op,
	input wire [63 : 0] rs1_data,
	
	output wire [63 : 0] csr_data
	//output wire exception
);

	reg [`REG_BUS] cycle;
	wire cycle_ren = (csr_addr == 12'hB00) & csr_rena;
	wire cycle_wen = (csr_addr == 12'hB00) & csr_wena;
	always
		@(posedge clk) begin
			if(cycle_wen) begin
				case(csr_op)
					`CSR_RW: begin
						cycle <= rs1_data;
					end
					`CSR_RS: begin
						cycle <= rs1_data | cycle;
					end
					`CSR_RC: begin
						cycle <= ~rs1_data & cycle;
					end
					default: begin
						cycle <= cycle;
					end
				endcase
			end
			else begin
				cycle <= cycle + 1;
			end
		end

	assign csr_data = {64{cycle_ren}} & cycle;

endmodule
