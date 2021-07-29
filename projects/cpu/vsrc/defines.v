
`timescale 1ns / 1ps

`define ZERO_WORD  64'h00000000_00000000   
`define REG_BUS    63 : 0     
//`define INST_ADD   8'h11

/* ----id stage---- */

//opcode
`define OP_IMM 7'b0010011
`define BRANCH 7'b1100011
`define JAL 7'b1100111
`define JALR 7'b1101111

//func3
`define FUN3_ADDI 3'b000
`define FUN3_SLTI 3'b010
`define FUN3_SLTIU 3'b011
`define FUN3_XORI 3'b100
`define FUN3_ORI 3'b110
`define FUN3_ANDI 3'b111
`define FUN3_SLLI 3'b001
`define FUN3_SRLI 3'b101
`define FUN3_SRAI 3'b101		//same as SRLI, differed by inst[30]

`define REG_RENABLE 1'b1
`define REG_RDISABLE 1'b0
`define REG_WENABLE 1'b1
`define REG_WDISABLE 1'b0

/* ----exe stage---- */
`define ALU_OP_BUS 3:0
`define ALU_ZERO 4'b0000
`define ALU_ADD	4'b0001
