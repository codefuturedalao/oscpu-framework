`include "defines.v"

module hazard_unit(
	input wire clk,
	input wire rst,
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
	input wire branch,
	input wire jump,
	input wire b_flag,
	//input wire control_transfer,
	input wire exception_transfer_i,
	input wire [`REG_BUS] control_target_pc_i,
	input wire [`REG_BUS] exception_target_pc_i,

	input wire if_stall_req,
	input wire exe_stall_req,
	input wire mem_stall_req,
	
	/* TODO: think a better way to set stall and flush */
	output wire control_transfer_o,
	output wire exception_transfer_o,
	output wire [`REG_BUS] control_target_pc_o,
	output wire [`REG_BUS] exception_target_pc_o,
	output reg [1 : 0] pc_stall,
	output reg [1 : 0] if_id_stall,
	output reg [1 : 0] id_ex_stall,
	output reg [1 : 0] ex_me_stall,
	output reg [1 : 0] me_wb_stall
);
	wire control_transfer;
	reg exception_transfer_r;
	reg control_transfer_r;
	reg [`REG_BUS] control_target_pc_r;
	reg [`REG_BUS] exception_target_pc_r;
	/*assign control_transfer_o = (~if_stall_req & control_transfer) ? control_transfer : control_transfer_r;
	assign exception_transfer_o = (~if_stall_req & exception_transfer_i) ? exception_transfer_i : exception_transfer_r;
	assign control_target_pc_o = (~if_stall_req & control_transfer) ? control_target_pc_i : control_target_pc_r;
	assign exception_target_pc_o = (~if_stall_req & exception_transfer_i) ? exception_target_pc_i : exception_target_pc_r;
*/	assign control_transfer_o =  control_transfer | control_transfer_r;
	assign exception_transfer_o = exception_transfer_i | exception_transfer_r;
	assign control_target_pc_o =  control_target_pc_i | control_target_pc_r;
	assign exception_target_pc_o = exception_target_pc_i | exception_target_pc_r;

	always
    	@(posedge clk) begin
			if(rst == 1'b1) begin
				exception_transfer_r <= 1'b0;
				exception_target_pc_r <= {64{1'b0}};
			end
			else if(if_stall_req == 1'b1 && exception_transfer_i) begin
				exception_transfer_r <= exception_transfer_i;
				exception_target_pc_r <= exception_target_pc_i;
			end
			else if(if_stall_req == 1'b0) begin//pc=next
				exception_transfer_r <= 1'b0;
				exception_target_pc_r <= {64{1'b0}};
			end
		end


	always
		@(posedge clk) begin
			if(rst == 1'b1) begin
				control_transfer_r <= 1'b0;
				control_target_pc_r <= {64{1'b0}};
			end
			else if(if_stall_req == 1'b1 && control_transfer) begin
				control_transfer_r <= control_transfer;
				control_target_pc_r <= control_target_pc_i;
			end
			else if(if_stall_req == 1'b0) begin
				control_transfer_r <= 1'b0;
				control_target_pc_r <= {64{1'b0}};
			end
			
		end


	wire id_stall_req = (ex_csr_rena == 1'b1 && ((id_rs1_rena == 1'b1 && id_rs1_addr == ex_rd_waddr) || (id_rs2_rena == 1'b1 && id_rs2_addr == ex_rd_waddr)))
					| 	(ex_mem_rena == 1'b1 && ((id_rs1_rena == 1'b1 && id_rs1_addr == ex_rd_waddr) || (id_rs2_rena == 1'b1 && id_rs2_addr == ex_rd_waddr)));

	assign control_transfer = ((b_flag & branch) | jump) & ~exception_transfer_i;

	// if stall conflicts with transfer	and when stalled by other reason, should have reg to keep value
																							//if		//id		//ex		//mem		//wb
	assign {pc_stall, if_id_stall, id_ex_stall, ex_me_stall, me_wb_stall} = 
											     (exception_transfer_i & ~if_stall_req)? {`STALL_NEXT, `STALL_ZERO, `STALL_ZERO, `STALL_ZERO, `STALL_ZERO} :  //finish read transaction and the deal with transfer, so keep the mem stage
												 (exception_transfer_i & if_stall_req)? {`STALL_KEEP, `STALL_ZERO, `STALL_ZERO, `STALL_ZERO, `STALL_ZERO} :  //release wb stage, wait if finished, and store the value in exception_transfer_r
												(exception_transfer_r & if_stall_req)? {`STALL_KEEP, `STALL_ZERO, `STALL_ZERO, `STALL_ZERO, `STALL_ZERO} :  //still wait
											   (exception_transfer_r & ~if_stall_req)? {`STALL_NEXT, `STALL_ZERO, `STALL_ZERO, `STALL_ZERO, `STALL_ZERO} :	//exception hazard

													(control_transfer & if_stall_req)? {`STALL_KEEP, `STALL_ZERO, `STALL_ZERO, `STALL_ZERO, `STALL_NEXT} :  //control_transfer is 1 means no exception in wb stage, so release the stage	TODO:make sure no stage in mem, maybe doesn't matter
													(control_transfer & ~if_stall_req)? {`STALL_NEXT, `STALL_ZERO, `STALL_ZERO, `STALL_ZERO, `STALL_NEXT} :	//control hazard
													(control_transfer_r & if_stall_req)? {`STALL_KEEP, `STALL_ZERO, `STALL_ZERO, `STALL_ZERO, `STALL_ZERO} :  //control_transfer is 1 means no exception in wb stage, so release the stage	TODO:make sure no stage in mem, maybe doesn't matter
													(control_transfer_r & ~if_stall_req)? {`STALL_NEXT, `STALL_ZERO, `STALL_ZERO, `STALL_ZERO, `STALL_ZERO} :	//control hazard

																		mem_stall_req? {`STALL_KEEP, `STALL_KEEP, `STALL_KEEP, `STALL_KEEP, `STALL_KEEP} :	//load and store
																		exe_stall_req? {`STALL_KEEP, `STALL_KEEP, `STALL_KEEP, `STALL_ZERO, `STALL_NEXT} :	//mul and div
																		id_stall_req ? {`STALL_KEEP, `STALL_KEEP, `STALL_ZERO, `STALL_NEXT, `STALL_NEXT} :	//data hazard
																		if_stall_req ? {`STALL_KEEP, `STALL_ZERO, `STALL_NEXT, `STALL_NEXT, `STALL_NEXT} :	//fetch inst
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
