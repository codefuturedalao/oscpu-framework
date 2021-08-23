
`timescale 1ns / 1ps
`define CACHE

`define PC_START   64'h00000000_80000000  
`define PC_START_MINUS4   64'h00000000_7ffffffC  
`define ZERO_WORD  64'h00000000_00000000   
`define REG_BUS    63 : 0     
`define INST_BUS    31 : 0     
`define MXLEN	   64

`define AXI_ADDR_WIDTH      64
`define AXI_DATA_WIDTH      64
`define AXI_ID_WIDTH        4
`define AXI_USER_WIDTH      1

`define SIZE_B              3'b000
`define SIZE_H              3'b001
`define SIZE_W              3'b010
`define SIZE_D              3'b011
`define SIZE_L              3'b100

`define REQ_READ            1'b0
`define REQ_WRITE           1'b1

`define CHIP_EN 1'b0
`define CHIP_DI 1'b1
//`define INST_ADD   8'h11

/* ----id stage---- */
/*
	000		001		010		011		100		101		110		111
00	LOAD  LOAD-FP	cus0		   OP-IMM  AUIPC   OP-IMM-32
01	STORE STORE-FP	cus1	AMO	    OP		LUI		OP-32
10  MADD   MSUB    NMSUB   NMADD	OP-FP	res
11 BRANCH  JALR		res		JAL		SYS		res
*/
//stall
`define STALL_NEXT  2'b00
`define STALL_KEEP	2'b01
`define STALL_ZERO	2'b10
//opcode
`define OP_IMM 7'b0010011
`define OP_IMM32 7'b0011011
`define OP 7'b0110011
`define OP32 7'b0111011
`define LUI 7'b0110111
`define BRANCH 7'b1100011
`define JAL 7'b1101111
`define JALR 7'b1100111
`define AUIPC 7'b0010111
`define LOAD 7'b0000011
`define STORE 7'b0100011
`define SYSTEM 7'b1110011
`define CUS0 7'b0001011
`define INST_DISPLAY 32'h0005_2013
//0000000_00000_01010_000_00000_0001011 write() 0005000B

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

`define FUN3_LB 3'b000
`define FUN3_LH 3'b001
`define FUN3_LW 3'b010
`define FUN3_LBU 3'b100
`define FUN3_LHU 3'b101
`define FUN3_LWU 3'b110
`define FUN3_LD 3'b011


`define FUN3_SB 3'b000
`define FUN3_SH 3'b001
`define FUN3_SW 3'b010
`define FUN3_SD 3'b011

`define FUN3_CSRRW 3'b001
`define FUN3_CSRRS 3'b010
`define FUN3_CSRRC 3'b011
`define FUN3_CSRRWI 3'b101
`define FUN3_CSRRSI 3'b110
`define FUN3_CSRRCI 3'b111

`define FUN3_MUL 3'b000
`define FUN3_MULH 3'b001
`define FUN3_MULHSU 3'b010
`define FUN3_MULHU 3'b011
`define FUN3_DIV 3'b100
`define FUN3_DIVU 3'b101
`define FUN3_REM 3'b110
`define FUN3_REMU 3'b111
//func7
`define FUN7_M 7'b000_0001

`define REG_RENABLE 1'b1
`define REG_RDISABLE 1'b0
`define REG_WENABLE 1'b1
`define REG_WDISABLE 1'b0

`define OP1_REG 1'b0
`define OP1_PC 1'b1
`define OP2_REG 2'b00
`define OP2_IMM 2'b01
`define OP2_4  2'b10

`define RS1_EX 2'b00
`define RS1_ME 2'b01
`define RS1_WB 2'b10
`define RS2_EX 2'b00
`define RS2_ME 2'b01
`define RS2_WB 2'b10

`define NEXTPC_PC 1'b0
`define NEXTPC_REG 1'b1

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

`define ALU_ADDW 5'b10010
`define ALU_SUBW 5'b10011
`define ALU_SLLW 5'b10100
`define ALU_SRLW 5'b10101
`define ALU_SRAW 5'b10110

`define ALU_WRITE 5'b11111

/* ----mem stage---- */
`define MEM_UNSIGNED 1'b0
`define MEM_SIGNED 1'b1


/* ----wb stage---- */
`define CSR_RW 2'b01
`define CSR_RS 2'b10
`define CSR_RC 2'b11

`define CSR_CYCLE 12'hB00
`define CSR_MSTATUS	12'h300
`define CSR_MTVEC 12'h305
`define CSR_MEPC  12'h341
`define CSR_MCAUSE 12'h342

`define INST_ADDR_MISALIGN 5'b0_0000
`define INST_ACCESS_FAULT  5'b0_0001
`define ILLEGAL_INST	   5'b0_0010
`define BREAK_POINT		   5'b0_0011
`define LOAD_ADDR_MISALIGN 5'b0_0100
`define LOAD_ACCESS_FAULT  5'b0_0101
`define STORE_ADDR_MISALIGN 5'b0_0110
`define STORE_ACCESS_FAULT  5'b0_0111
`define MRET				5'b0_1000
`define SRET				5'b0_1001
`define URET				5'b0_1010
`define ECALL				5'b0_1011
`define INST_PAGE_FAULT		5'b0_1100
`define LOAD_PAGE_FAULT		5'b0_1101
//reserved for furture standard use
`define STORE_PAGE_FAULT	5'b0_1111
