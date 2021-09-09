`include "defines.v"

module int_detect(
	input wire ex_exception_flag_i,
	output wire ex_exception_flag_o,
	
	input wire inst_valid,

	input wire time_int,
	input wire soft_int,
	input wire [4 : 0] ex_exception_cause_i,
	output wire [4 : 0] ex_exception_cause_o
);

	assign ex_exception_flag_o = inst_valid & (ex_exception_flag_i |  (time_int | soft_int));

	//interrupt first
	assign ex_exception_cause_o = time_int ? `TIME_INT :  (soft_int ? `SOFT_INT : ex_exception_cause_i);


endmodule
