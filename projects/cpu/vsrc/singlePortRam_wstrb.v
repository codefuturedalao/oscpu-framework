
`include "defines.v"

module singlePortRam_wstrb #(
	parameter REG_WIDTH = 64,
	parameter REG_DEPTH = 64
)
(
	input wire clk,
	input wire rst,
	input wire [$clog2(REG_DEPTH) - 1 : 0] addr,
	input wire cs_n,
	input wire we,
	input wire [(REG_WIDTH >> 3)  - 1 : 0] wstrb,
	input wire [REG_WIDTH - 1 : 0] din,
	
	output wire [REG_WIDTH - 1 : 0] dout
);

	reg [REG_WIDTH - 1 : 0] dout_r;	
	assign dout = dout_r;
	reg [REG_WIDTH - 1 : 0] ram [REG_DEPTH - 1 : 0];


	//write
	always
		@(posedge clk) begin
			if(rst == 1'b1) begin
				for(integer i = 0; i < REG_DEPTH; i = i + 1) begin
					ram[i] = {REG_WIDTH{1'b0}};
				end 	
			end
			else if(~cs_n & we) begin
				ram[addr][7 : 0] <= wstrb[0] ? din[7 : 0] : ram[addr][7 : 0];
				ram[addr][15 : 8] <= wstrb[1] ? din[15 : 8] : ram[addr][15 : 8];
				ram[addr][23 : 16] <= wstrb[2] ? din[23 : 16] : ram[addr][23 : 16];
				ram[addr][31 : 24] <= wstrb[3] ? din[31 : 24] : ram[addr][31 : 24];
				ram[addr][39 : 32] <= wstrb[4] ? din[39 : 32] : ram[addr][39 : 32];
				ram[addr][47 : 40] <= wstrb[5] ? din[47 : 40] : ram[addr][47 : 40];
				ram[addr][55 : 48] <= wstrb[6] ? din[55 : 48] : ram[addr][55 : 48];
				ram[addr][63 : 56] <= wstrb[7] ? din[63 : 56] : ram[addr][63 : 56];
			end
		end

	//read
	always
		@(posedge clk) begin
			if(rst == 1'b1) begin
				dout_r <= {REG_WIDTH{1'b0}};
			end
			else if(~cs_n & we == 1'0) begin
				dout_r <= ram[addr];
			end
		end

endmodule
