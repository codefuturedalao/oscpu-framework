`include "defines.v"

module exe_stage(
  	input wire rst,
	input wire [`ALU_OP_BUS] alu_op,
	input wire pc_src,
	input wire [`REG_BUS] pc,
	input wire alu_op1_src,
	input wire [1 : 0] alu_op2_src,
	input wire [`REG_BUS] imm,
	
	input wire [1 : 0] rs1_src,
	input wire [1 : 0] rs2_src,
	input wire [`REG_BUS] ex_rs1_data,
	input wire [`REG_BUS] ex_rs2_data,
	input wire [`REG_BUS] me_alu_result,
	input wire [`REG_BUS] wb_rd_data,
  
	output wire [`REG_BUS] new_rs1_data,
	output wire [`REG_BUS] new_rs2_data,
  	output reg  [`REG_BUS] alu_result,
	output wire [`REG_BUS] target_pc,
	output reg b_flag			//indicate branch is successful or not
);

wire overflow;
wire sign;
wire cout;
wire carry;
wire zero;
reg cin;
reg [`REG_BUS] op1_add;
reg [`REG_BUS] op2_add; 
wire [`REG_BUS] result_add; 

wire [`REG_BUS]op1;
wire [`REG_BUS]op2;
//wire [`REG_BUS]new_rs1_data;
//wire [`REG_BUS]new_rs2_data;

/* select new_rs1_data and new_rs2_data to solve data hazard */
rs1_mux Rs1_mux(.ex_rs1_data(ex_rs1_data), .me_alu_result(me_alu_result), .wb_rd_data(wb_rd_data), .rs1_src(rs1_src), .new_rs1_data(new_rs1_data));
rs2_mux Rs2_mux(.ex_rs2_data(ex_rs2_data), .me_alu_result(me_alu_result), .wb_rd_data(wb_rd_data), .rs2_src(rs2_src), .new_rs2_data(new_rs2_data)); 
/* select op1 and op2 */
op1_mux Op1_mux(.new_rs1_data(new_rs1_data), .pc(pc), .alu_op1_src(alu_op1_src), .op1(op1));
op2_mux Op2_mux(.new_rs2_data(new_rs2_data), .imm(imm), .alu_op2_src(alu_op2_src), .op2(op2));
/* add or sub */
always
	@(*) begin
		case( alu_op ) 
	  		`ALU_SUB, `ALU_SUBW, `ALU_SLT, `ALU_SLTU,`ALU_BEQ, `ALU_BNE, `ALU_BLT, `ALU_BGE, `ALU_BLTU, `ALU_BGEU: begin
			     op1_add = op1;
				 op2_add = ~op2; 
			     cin = 1'b1;
			end
			default : begin
				op1_add = op1;
				op2_add = op2;
				cin = 1'b0;
			end			
		endcase
	end

always @(*) begin
	if(alu_op == `ALU_WRITE) begin
	$display("%c", op1[7 : 0]);
	end
end

/* calculate alu_result */
//caution: i am not sure >>> is arth shift due to some reason
//answer: not work
wire [`REG_BUS] sll_result = op1 << op2[5 : 0];
wire [31 : 0] sll_result32 = op1[31:0] << op2[4 : 0];
wire [`REG_BUS] srl_result = op1 >> op2[5 : 0];
wire [31 : 0] srl_result32 = op1[31 : 0] >> op2[4 : 0];
wire [`REG_BUS] sra_result = (op1 >> op2[5:0]) | (op1[63] ? ~({64{1'b1}} >> op2[5:0]) : {64'b0});
wire [31 : 0] sra_result32 = (op1[31 : 0] >> op2[4:0]) | (op1[31] ? ~({32{1'b1}} >> op2[4:0]) : {32'b0});
always
	@(*) begin
 		if( rst == 1'b1 ) begin
    		alu_result = `ZERO_WORD;
  		end
  		else begin
    		case( alu_op )
	  			`ALU_ADD: begin alu_result = result_add; end
	  			`ALU_ADDW: begin alu_result = {{32{result_add[31]}}, result_add[31 : 0]}; end
	  			`ALU_SUB: begin alu_result = result_add; end
	  			`ALU_SUBW: begin alu_result = {{32{result_add[31]}}, result_add[31 : 0]}; end
	 			`ALU_SLT: begin alu_result = {63'b0 , sign ^ overflow}; end
	  			`ALU_SLTU: begin alu_result = {63'b0, carry}; end
	  			`ALU_XOR: begin alu_result = op1 ^ op2;  end
	  			`ALU_OR: begin alu_result = op1 | op2;  end
	  			`ALU_AND: begin alu_result = op1 & op2;  end
	  			`ALU_SLL: begin alu_result = sll_result;  end
	  			`ALU_SRL: begin alu_result = srl_result;  end
	  			`ALU_SRA: begin alu_result = sra_result;  end
	  			`ALU_SLLW: begin alu_result = {{32{sll_result32[31]}}, sll_result32[31:0]};  end
	  			`ALU_SRLW: begin alu_result = {{32{srl_result32[31]}}, srl_result32[31:0]};  end
	  			`ALU_SRAW: begin alu_result = {{32{sra_result32[31]}}, sra_result32[31:0]};  end
	  			`ALU_LUI: begin alu_result = op2;  end
	  			default:  begin alu_result = `ZERO_WORD; end
			endcase
  		end
	end

/* branch flag */
always
	@(*) begin
 		if( rst == 1'b1 ) begin
			b_flag = 1'b0;
  		end
  		else begin
    		case( alu_op )
				`ALU_BEQ: begin b_flag = zero; end
				`ALU_BNE: begin b_flag = ~zero; end
				`ALU_BLT: begin b_flag = sign ^ overflow; end
				`ALU_BGE: begin b_flag = ~(sign ^ overflow); end
				`ALU_BLTU: begin b_flag = carry; end
				`ALU_BGEU: begin b_flag = ~carry; end
	  			default:  begin 
					b_flag = 1'b0;
				end
			endcase
		end
	end

adder64 myadder(op1_add, op2_add, cin, result_add, overflow, sign, cout, carry, zero);
/* calculate traget instruction's pc for branch and jump */
wire [`REG_BUS] pc_op1;
wire [`REG_BUS] target_pc_tmp;
assign pc_op1 = (pc_src == 1'b1) ? new_rs1_data : pc;
assign target_pc = {target_pc_tmp[63:1], pc_src == 1 ? 1'b0 : target_pc_tmp[0]};		//JALR make the least significant bit zero
adder64 Pcadder(.op1(pc_op1), .op2(imm), .cin(0), .result(target_pc_tmp), .zero(), .sign(), .overflow(), .carry(), .cout());


endmodule
