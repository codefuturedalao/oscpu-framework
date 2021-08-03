`include "defines.v"

module hazard_unit(
	/*data hazard*/
	input wire ex_mem_rena,
	input wire [4 : 0] ex_rd_waddr,
	
	input wire id_rs1_rena,
	input wire [4 : 0] id_rs1_addr,
	input wire id_rs2_rena,
	input wire [4 : 0] id_rs2_addr,
	input wire transfer,

	
	/* TODO: think a better way to set stall and flush */
	output reg [1 : 0] pc_stall,
	output reg [1 : 0] if_id_stall,
	output reg [1 : 0] id_ex_stall,
	output reg [1 : 0] ex_me_stall,
	output reg [1 : 0] me_wb_stall
);
	
always
	@(*) begin
		/* control hazard */
		if(transfer == 1'b1) begin	
			pc_stall = `STALL_NEXT;
			if_id_stall = `STALL_ZERO;
			id_ex_stall = `STALL_ZERO;
			ex_me_stall = `STALL_ZERO;
			me_wb_stall = `STALL_NEXT;
		end
		/* data hazard */
		else if(ex_mem_rena == 1'b1 && ((id_rs1_rena == 1'b1 && id_rs1_addr == ex_rd_waddr) || (id_rs2_rena == 1'b1 && id_rs2_addr == ex_rd_waddr)) ) begin
			pc_stall = `STALL_KEEP;
			if_id_stall = `STALL_KEEP;
			id_ex_stall = `STALL_ZERO;
			ex_me_stall = `STALL_NEXT;
			me_wb_stall = `STALL_NEXT;
		end
		else begin
			pc_stall = `STALL_NEXT;
			if_id_stall = `STALL_NEXT;
			id_ex_stall = `STALL_NEXT;
			ex_me_stall = `STALL_NEXT;
			me_wb_stall = `STALL_NEXT;
		end
	end
	


endmodule
