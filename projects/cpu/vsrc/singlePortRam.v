`include "defines.v"

module singlePortRam #(
	parameter REG_WIDTH = 64,
	parameter REG_DEPTH = 64
)
(
	input wire clk,
	input wire rst,
	input wire [$clog2(REG_DEPTH) - 1 : 0] addr,
	input wire cs_n,
	input wire we,
	//input wire [REG_WIDTH / 8  - 1] wstrb,
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
				ram[addr] <= din;
			end
		end

	//read
	always
		@(posedge clk) begin
			if(rst == 1'b1) begin
				dout_r <= {REG_WIDTH{1'b0}};
			end
			else if(~cs_n & we) begin
				dout_r <= ram[addr];
			end
		end

endmodule
