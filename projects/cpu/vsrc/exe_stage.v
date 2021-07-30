`include "defines.v"

module exe_stage(
  input wire rst,
  //input wire [4 : 0]inst_type_i,
  //input wire [7 : 0]inst_opcode,
	input wire [`ALU_OP_BUS] alu_op,
  input wire [`REG_BUS]op1,
  input wire [`REG_BUS]op2,
  
 // output wire [4 : 0]inst_type_o,
  output reg  [`REG_BUS]rd_data,
	output reg b_flag			//indicate branch is successful or not
);

//assign inst_type_o = inst_type_i;
wire overflow;
wire sign;
wire cout;
wire carry;
wire zero;
reg cin;	//maybe reg
reg [`REG_BUS] op1_add;
reg [`REG_BUS] op2_add; 
wire [`REG_BUS] result_add; 

/* add or sub */
always
	@(*) begin
		case( alu_op ) 
	  		`ALU_SUB,  `ALU_SLT, `ALU_SLTU,`ALU_BEQ, `ALU_BNE, `ALU_BLT, `ALU_BGE, `ALU_BLTU, `ALU_BGEU: begin
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

/* calculate rd_data */
always
	@(*) begin
 		if( rst == 1'b1 ) begin
    		rd_data = `ZERO_WORD;
  		end
  		else begin
    		case( alu_op )
	  			`ALU_ADD: begin rd_data = result_add; end
	  			`ALU_SUB: begin rd_data = result_add; end
	 			`ALU_SLT: begin rd_data = {63'b0 , sign ^ overflow}; end
	  			`ALU_SLTU: begin rd_data = {63'b0, carry}; end
	  			`ALU_XOR: begin rd_data = op1 ^ op2;  end
	  			`ALU_OR: begin rd_data = op1 | op2;  end
	  			`ALU_AND: begin rd_data = op1 & op2;  end
	  			`ALU_SLL: begin rd_data = op1 << op2;  end
	  			`ALU_SRL: begin rd_data = op1 >> op2;  end
	  			`ALU_SRA: begin rd_data = op1 >>> op2;  end
	  			`ALU_LUI: begin rd_data = op2;  end
	  			default:  begin rd_data = `ZERO_WORD; end
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


endmodule
