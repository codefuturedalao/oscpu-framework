`include "defines.v"
module pc_mux(
	input wire[`REG_BUS] old_pc,
	input wire branch,
	input wire[1:0] jump,
	input wire b_flag,
	input wire [`REG_BUS] b_offset,
	input wire [`REG_BUS] j_offset,
	input wire [`REG_BUS] rs1_data,

	output reg[`REG_BUS] new_pc
);
	/*TODO:
	i am not sure whether i should calculate new pc here, because i can use old_pc as op1 adn b_offset(or 4) as op2, then use rd_data as new_pc
	then i can save an adder, but i think that's too late for unconditional jump
	so i need to figure it out when i handle the pipeline micro-A
	*/
	reg [`REG_BUS] op1;
	reg [`REG_BUS] op2;
	wire [`REG_BUS] result;
	assign result = op1 + op2;
	assign new_pc = {result[63:1], jump[0] == 1 ? 1'b0 : result[0]};		//JALR make the least significant bit zero

	always
		@(*) begin
			if((branch & b_flag) == 1'b1) begin
				op1 = b_offset;
			end
			else begin
				if(|jump == 1'b1) begin
					op1 = j_offset;
				end
				else begin
					op1 = 4;
				end
			end
		end

	always
		@(*) begin
			if(jump[0] == 1'b1) begin
				op2 = rs1_data;
			end
			else begin	//no branch, JAL, branch
				op2 = old_pc;
			end
		end

endmodule
