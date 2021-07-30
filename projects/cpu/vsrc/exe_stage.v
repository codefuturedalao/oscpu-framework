`include "defines.v"

module exe_stage(
  input wire rst,
  //input wire [4 : 0]inst_type_i,
  //input wire [7 : 0]inst_opcode,
	input wire [`ALU_OP_BUS] alu_op,
  input wire [`REG_BUS]op1,
  input wire [`REG_BUS]op2,
  
 // output wire [4 : 0]inst_type_o,
  output reg  [`REG_BUS]rd_data
);

//assign inst_type_o = inst_type_i;
wire overflow;
wire sign;
wire cout;
wire carry;
reg cin;	//maybe reg
reg [`REG_BUS] op1_add;
reg [`REG_BUS] op2_add; 
wire [`REG_BUS] result_add; 

always
	@(*) begin
 		if( rst == 1'b1 ) begin
			op1_add = op1;
			op2_add = op2;
			cin = 1'b0;
    		rd_data = `ZERO_WORD;
  		end
  		else begin
			op1_add = op1;
			op2_add = op2;
			cin = 1'b0;
    		case( alu_op )
	  			`ALU_ADD: begin 
					//already set op1 and op2 
					//rd_data = result_add;  
					rd_data = `ZERO_WORD;
				end
	 			`ALU_SLT: begin 
					//op1_add = op1;
					op2_add = ~op2;
					cin = 1'b1;
					rd_data = {63'b0 , sign ^ overflow};
				end
	  			`ALU_SLTU: begin 
					rd_data = {63'b0, carry};  
				end
	  			`ALU_XOR: begin rd_data = op1 ^ op2;  end
	  			`ALU_OR: begin rd_data = op1 | op2;  end
	  			`ALU_AND: begin rd_data = op1 & op2;  end
	  			`ALU_SLL: begin rd_data = op1 << op2;  end
	  			`ALU_SRL: begin rd_data = op1 >> op2;  end
	  			`ALU_SRA: begin rd_data = op1 >>> op2;  end
	  			default:  begin 
					rd_data = `ZERO_WORD; 
				end
			endcase
  		end
	end


adder64 myadder(op1_add, op2_add, cin, result_add, overflow, sign, cout, carry);


endmodule
