
`timescale 1ns / 1ps

`define PC_START   64'h00000000_80000000  
`define ZERO_WORD  64'h00000000_00000000   
`define REG_BUS    63 : 0     
//`define INST_ADD   8'h11

/* ----id stage---- */
/*
	000		001		010		011		100		101		110		111
00	LOAD  LOAD-FP	cus0		   OP-IMM  AUIPC   OP-IMM-32
01	STORE STORE-FP	cus1	AMO	    OP		LUI		OP-32
10  MADD   MSUB    NMSUB   NMADD	OP-FP	res
11 BRANCH  JALR		res		JAL		SYS		res
*/
//opcode
`define OP_IMM 7'b0010011
`define OP 7'b0110011
`define LUI 7'b0110111
`define BRANCH 7'b1100011
`define JAL 7'b1101111
`define JALR 7'b1100111
`define AUIPC 7'b0010111

//func3
`define FUN3_ADDI 3'b000
`define FUN3_SLTI 3'b010
`define FUN3_SLTIU 3'b011
`define FUN3_XORI 3'b100
`define FUN3_ORI 3'b110
`define FUN3_ANDI 3'b111
`define FUN3_SL 3'b001
`define FUN3_SR 3'b101

//same as I inst
`define FUN3_ADD_SUB 3'b000		//ADD or SUB
//`define FUN3_SL 3'b001
`define FUN3_SLT 3'b010
`define FUN3_SLTU 3'b011
`define FUN3_XOR 3'b100
//define FUN3_SR 3'b101
`define FUN3_OR 3'b110
`define FUN3_AND 3'b111

`define FUN3_BEQ 3'b000
`define FUN3_BNE 3'b001
`define FUN3_BLT 3'b100
`define FUN3_BGE 3'b101
`define FUN3_BLTU 3'b110
`define FUN3_BGEU 3'b111

`define REG_RENABLE 1'b1
`define REG_RDISABLE 1'b0
`define REG_WENABLE 1'b1
`define REG_WDISABLE 1'b0

/* ----exe stage---- */
`define ALU_OP_BUS 4:0
`define ALU_ZERO 5'b00000
`define ALU_ADD	5'b00001
`define ALU_SLT	5'b00010
`define ALU_SLTU 5'b00011
`define ALU_XOR 5'b00100
`define ALU_OR 5'b00101
`define ALU_AND 5'b00110
`define ALU_SLL 5'b00111
`define ALU_SRL 5'b01000
`define ALU_SRA 5'b01001
`define ALU_SUB	5'b01010
`define ALU_LUI	5'b01011

`define ALU_BEQ	5'b01100
`define ALU_BNE	5'b01101
`define ALU_BLT	5'b01110
`define ALU_BGE	5'b01111
`define ALU_BLTU	5'b10000
`define ALU_BGEU	5'b10001
