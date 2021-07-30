
//--xuezhen--

`include "defines.v"

module id_stage(
  	input wire rst,
  	input wire [31 : 0]inst,
	input wire [`REG_BUS] pc,
  	input wire [`REG_BUS]rs1_data,
  	input wire [`REG_BUS]rs2_data,
  	
  		
  	output reg rs1_r_ena,
  	output wire [4 : 0]rs1_r_addr,
  	output reg rs2_r_ena,
  	output wire [4 : 0]rs2_r_addr,
  	output reg rd_w_ena,
  	output wire [4 : 0]rd_w_addr,
  
  	//output wire [4 : 0]inst_type,
  	//output wire [7 : 0]inst_opcode,
  	output reg [`ALU_OP_BUS] alu_op,
  	output reg [`REG_BUS]op1,
  	output reg [`REG_BUS]op2,
	output wire branch,
	output wire [`REG_BUS] b_offset,
	output wire [1:0] jump,
	output wire [`REG_BUS] j_offset
);


wire [6  : 0]opcode;
wire [4  : 0]rd;
wire [2  : 0]func3;
wire [2  : 0]func7;
wire [4  : 0]rs1;
wire [4  : 0]rs2;

wire [`REG_BUS] immI = {{52{inst[31]}}, inst[31 : 20]};
wire [`REG_BUS] immS = {{52{inst[31]}}, inst[31 : 25], inst[11 : 7]};
wire [`REG_BUS] immB = {{52{inst[31]}}, inst[7] ,inst[30 : 25], inst[11 : 8], 1'b0};
wire [`REG_BUS] immU = {{32{inst[31]}}, inst[31 : 12], 12'b0};
wire [`REG_BUS] immJ = {{44{inst[31]}}, inst[19 : 12], inst[20], inst[30 : 21], 1'b0};

/* use wire not always to generate combinational circuit for fun, no other reason..., may be bad for
   forward compatibility */
assign branch = opcode[6] & opcode[5] & ~opcode[4] & ~opcode[3] & ~opcode[2] & opcode[1] & opcode[0];
assign jump[0] = (opcode[6] & opcode[5] & ~opcode[4] & ~opcode[3] & opcode[2] & opcode[1] & opcode[0] );		//JALR
assign jump[1] =  (opcode[6] & opcode[5] & ~opcode[4] & opcode[3] & opcode[2] & opcode[1] & opcode[0] );		//JAL
//load
wire mem_to_reg = ~opcode[6] & ~opcode[5] & ~opcode[4] & ~opcode[3] & ~opcode[2] & opcode[1] & opcode[0];
//store 
wire mem_w_ena = ~opcode[6] & opcode[5] & ~opcode[4] & ~opcode[3] & ~opcode[2] & opcode[1] & opcode[0];

assign b_offset = immB;
assign j_offset = jump[0] == 1 ? immI : (jump[1] == 1 ? immJ : `ZERO_WORD);



assign opcode = inst[6  :  0];
assign rd     = inst[11 :  7];
assign func3  = inst[14 : 12];
assign func7  = inst[31 : 25];
assign rs1    = inst[19 : 15];
assign rs2    = inst[24 : 20];

assign rs1_r_addr = ( rst == 1'b1 ) ? 0 : rs1;
assign rs2_r_addr = ( rst == 1'b1 ) ? 0 : rs2;
assign rd_w_addr  = ( rst == 1'b1 ) ? 0 : rd;


always
    @(*) begin
		if(rst == 1'b1) begin
			//all signals are set invalid
			rs1_r_ena = `REG_RDISABLE;
			rs2_r_ena = `REG_RDISABLE;
			rd_w_ena = `REG_WDISABLE;
			op1 = `ZERO_WORD;
			op2 = `ZERO_WORD;
			alu_op = `ALU_ZERO;
		end
		else begin
			case(opcode)
				`OP_IMM : begin			//register-immediate instruction
				//addi slti sltiu xori ori andi slli srli srai	
					rs1_r_ena = `REG_RENABLE;
					rs2_r_ena = `REG_RDISABLE;						
					rd_w_ena = `REG_WENABLE;
					op1 = rs1_data;
					op2 = immI;
					case(func3)
						`FUN3_ADDI : begin	alu_op = `ALU_ADD; end
						`FUN3_SLTI : begin  alu_op = `ALU_SLT; end
						`FUN3_SLTIU : begin alu_op = `ALU_SLTU; end
						`FUN3_XORI : begin alu_op = `ALU_XOR; end
						`FUN3_ORI: begin alu_op = `ALU_OR; end
						`FUN3_ANDI : begin alu_op = `ALU_AND; end
						`FUN3_SL : begin
							alu_op = `ALU_SLL;
							op2 = {58'b0, inst[25:20]};
						end
						`FUN3_SR : begin
							op2 = {58'b0, inst[25:20]};
							case(inst[30]) 
								1'b0 : begin		//logical
									alu_op = `ALU_SRL;
								end
								1'b1 : begin
									alu_op = `ALU_SRA;
								end
							endcase
						end
						default : begin alu_op = `ALU_ZERO; end
					endcase
				end
				`OP: begin
					rs1_r_ena = `REG_RENABLE;
					rs2_r_ena = `REG_RENABLE;						
					rd_w_ena = `REG_WENABLE;
					op1 = rs1_data;
					op2 = rs2_data;
					case(func3)
						`FUN3_ADD_SUB : begin
							case(inst[30])
								1'b0 : begin		//ADD
									alu_op = `ALU_ADD;
								end
								1'b1 : begin
									alu_op = `ALU_SUB;
								end
							endcase
						end
						`FUN3_SLT : begin  alu_op = `ALU_SLT; end
						`FUN3_SLTU : begin alu_op = `ALU_SLTU; end
						`FUN3_XOR : begin alu_op = `ALU_XOR; end
						`FUN3_OR: begin alu_op = `ALU_OR; end
						`FUN3_AND : begin alu_op = `ALU_AND; end
						`FUN3_SL : begin alu_op = `ALU_SLL; end
						`FUN3_SR : begin
							case(inst[30]) 
								1'b0 : begin		//logical
									alu_op = `ALU_SRL;
								end
								1'b1 : begin
									alu_op = `ALU_SRA;
								end
							endcase
						end
						default: begin alu_op = `ALU_ZERO; end
					endcase	
				end
				`LUI: begin
					rs1_r_ena = `REG_RDISABLE;
					rs2_r_ena = `REG_RDISABLE;
					rd_w_ena = `REG_WENABLE;
					op1 = `ZERO_WORD;
					op2 = immU;
					alu_op = `ALU_LUI;
				end
				`BRANCH: begin
					rs1_r_ena = `REG_RENABLE;
					rs2_r_ena = `REG_RENABLE;
					rd_w_ena = `REG_WDISABLE;
					op1 = rs1_data;
					op2 = rs2_data;
					case(func3)
						`FUN3_BEQ: begin alu_op = `ALU_BEQ; end	
						`FUN3_BNE: begin alu_op = `ALU_BNE; end	
						`FUN3_BLT: begin alu_op = `ALU_BLT; end	
						`FUN3_BGE: begin alu_op = `ALU_BGE; end	
						`FUN3_BLTU: begin alu_op = `ALU_BLTU; end	
						`FUN3_BGEU: begin alu_op = `ALU_BGEU; end	
						default: begin alu_op = `ALU_ZERO; end
					endcase
				end
				//actually it is a default situation
				`JAL: begin
					rs1_r_ena = `REG_RDISABLE;
					rs2_r_ena = `REG_RDISABLE;
					rd_w_ena = `REG_WENABLE;		//pc + 4
					op1 = pc;
					op2 = 4;
					alu_op = `ALU_ADD;		
				end
				`JALR: begin
					rs1_r_ena = `REG_RENABLE;		//rs + imm
					rs2_r_ena = `REG_RDISABLE;
					rd_w_ena = `REG_WENABLE;		//pc + 4
					op1 = pc;
					op2 = 4;
					alu_op = `ALU_ADD;		
				end
				default : begin
					rs1_r_ena = `REG_RDISABLE;
					rs2_r_ena = `REG_RDISABLE;
					rd_w_ena = `REG_WDISABLE;
					op1 = `ZERO_WORD;
					op2 = `ZERO_WORD;
					alu_op = `ALU_ZERO;
				end
				
			endcase
		end
    end

endmodule
