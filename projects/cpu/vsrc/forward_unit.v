`include "defines.v"

module forward_unit(
	input wire [4 : 0] ex_rs1_addr,
	input wire [4 : 0] ex_rs2_addr,
	
	input wire me_rd_wena,
	input wire [4 : 0] me_rd_waddr,
	
	input wire wb_rd_wena,
	input wire [4 : 0] wb_rd_waddr, 

	output reg [1 : 0] rs1_src,
	output reg [1 : 0] rs2_src
);

always
	@(*) begin
		if(me_rd_wena == 1'b1 && me_rd_waddr != 5'b0 && me_rd_waddr == ex_rs1_addr) begin
			rs1_src = `RS1_ME;
		end
		else if(wb_rd_wena == 1'b1 && wb_rd_waddr != 5'b0 && wb_rd_waddr == ex_rs1_addr) begin
			rs1_src = `RS1_WB;
		end
		else begin
			rs1_src = `RS1_EX;
		end
	end

always
	@(*) begin
		if(me_rd_wena == 1'b1 && me_rd_waddr != 5'b0 && me_rd_waddr == ex_rs2_addr) begin
			rs2_src = `RS2_ME;
		end
		else if(wb_rd_wena == 1'b1 && wb_rd_waddr != 5'b0 && wb_rd_waddr == ex_rs2_addr) begin
			rs2_src = `RS2_WB;
		end
		else begin
			rs2_src = `RS2_EX;
		end
	end

endmodule
