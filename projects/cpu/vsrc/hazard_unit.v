`include "defines.v"

module hazard_unit(
	/*data hazard*/
	input wire ex_mem_rena,
	input wire [4 : 0] ex_rd_waddr,
	input wire [4 : 0] me_rd_waddr,
	input wire ex_csr_rena,
	input wire me_csr_rena,
	
	input wire id_rs1_rena,
	input wire [4 : 0] id_rs1_addr,
	input wire id_rs2_rena,
	input wire [4 : 0] id_rs2_addr,
	input wire transfer,

	input wire exe_stall_req,
	
	/* TODO: think a better way to set stall and flush */
	output reg [1 : 0] pc_stall,
	output reg [1 : 0] if_id_stall,
	output reg [1 : 0] id_ex_stall,
	output reg [1 : 0] ex_me_stall,
	output reg [1 : 0] me_wb_stall
);

	wire id_stall_req = (ex_csr_rena == 1'b1 && ((id_rs1_rena == 1'b1 && id_rs1_addr == ex_rd_waddr) || (id_rs2_rena == 1'b1 && id_rs2_addr == ex_rd_waddr)))
					| 	(ex_mem_rena == 1'b1 && ((id_rs1_rena == 1'b1 && id_rs1_addr == ex_rd_waddr) || (id_rs2_rena == 1'b1 && id_rs2_addr == ex_rd_waddr)));
	
																							//if		//id		//ex		//mem		//wb
	assign {pc_stall, if_id_stall, id_ex_stall, ex_me_stall, me_wb_stall} = transfer ? {`STALL_NEXT, `STALL_ZERO, `STALL_ZERO, `STALL_ZERO, `STALL_NEXT} :	//control hazard
																		exe_stall_req? {`STALL_KEEP, `STALL_KEEP, `STALL_KEEP, `STALL_ZERO, `STALL_NEXT} :	//mul and div
																		id_stall_req ? {`STALL_KEEP, `STALL_KEEP, `STALL_ZERO, `STALL_NEXT, `STALL_NEXT} :	//data hazard
																					   {`STALL_NEXT, `STALL_NEXT, `STALL_NEXT, `STALL_NEXT, `STALL_NEXT} ;	//default

/*
		else if(me_csr_rena == 1'b1 &&  ((id_rs1_rena == 1'b1 && id_rs1_addr == me_rd_waddr) || (id_rs2_rena == 1'b1 && id_rs2_addr == me_rd_waddr)) ) begin

			pc_stall = `STALL_KEEP;
			if_id_stall = `STALL_KEEP;
			id_ex_stall = `STALL_ZERO;		//let inst in ex stage keep going
			ex_me_stall = `STALL_NEXT;
			me_wb_stall = `STALL_NEXT;
		end
*/
endmodule
