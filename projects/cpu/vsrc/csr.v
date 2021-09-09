`include "defines.v"
module csr(
	input wire clk,
	input wire rst,
	input wire [11 : 0] csr_addr,
	input wire csr_rena,
	input wire csr_wena,
	input wire [1 : 0] csr_op,
	input wire [63 : 0] csr_wdata,
//	input wire [63 : 0] rs1_data,
	input wire time_irq,
	input wire soft_irq,

	output wire time_int,
	output wire soft_int,
	//exception
	input wire exception_flag,
	input wire [4 : 0] exception_cause,
	input wire [`REG_BUS] epc,
	
	output wire [63 : 0] csr_data,
	output wire exception_transfer,
	output wire [`REG_BUS] exception_target_pc,

	output wire [`MXLEN-1 : 0] diff_mscratch,
	output wire [`MXLEN-1 : 0] diff_mstatus,
	output wire [`MXLEN-1 : 0] diff_sstatus,
	output wire [`MXLEN-1 : 0] diff_mcause,
	output wire [`MXLEN-1 : 0] diff_mepc,
	output wire [`MXLEN-1 : 0] diff_mtvec,
	output wire [`MXLEN-1 : 0] diff_mip,
	output wire [`MXLEN-1 : 0] diff_mie
);
	assign time_int = mstatus_ie[3] & tip[3] & tie[3];
	assign soft_int = mstatus_ie[3] & sip[3] & sie[3];

	//TODO: check mtvec align
	assign exception_transfer = exception_flag;
	assign exception_target_pc = exception_cause == `MRET ? mepc : (mtvec[1 : 0] == 2'b00 ? mtvec : 
				(exception_cause[4] == 1'b1 ? (mtvec + {exception_cause[3 : 0], 2'b00}) : mtvec));

	wire [3 : 0] sip;
	wire [3 : 0] tip;
	wire [3 : 0] eip;

	assign tip[3] = time_irq;
	assign sip[3] = soft_irq;

	reg [3 : 0] sie;
	reg [3 : 0] tie;
	reg [3 : 0] eie;
		
	wire ip_ren = (csr_addr == `CSR_MIP) & csr_rena & ~exception_flag;
	wire ip_wen = (csr_addr == `CSR_MIP) & csr_wena & ~exception_flag;	//cannot write

	wire ie_ren = (csr_addr == `CSR_MIE) & csr_rena & ~exception_flag;
	wire ie_wen = (csr_addr == `CSR_MIE) & csr_wena & ~exception_flag;
	
	always
		@(posedge clk) begin
			if(ie_wen) begin
				case(csr_op)
					`CSR_RW: begin
						{eie, tie, sie} <= csr_wdata[11 : 0];
					end
					`CSR_RS: begin
						{eie, tie, sie} <= csr_wdata[11 : 0] | {eie, tie, sie};
					end
					`CSR_RC: begin
						{eie, tie, sie} <= ~csr_wdata & {eie, tie, sie};
					end
					default: begin
						{eie, tie, sie} <= {eie, tie, sie};
					end
				endcase
			end
		end


	//TODO: what if interrupt with csrrw instruction??
	reg [`REG_BUS] cycle;
	wire cycle_ren = (csr_addr == `CSR_CYCLE) & csr_rena & ~exception_flag;
	wire cycle_wen = (csr_addr == `CSR_CYCLE) & csr_wena & ~exception_flag;
	always
		@(posedge clk) begin
			if(cycle_wen) begin
				case(csr_op)
					`CSR_RW: begin
						cycle <= csr_wdata;
					end
					`CSR_RS: begin
						cycle <= csr_wdata | cycle;
					end
					`CSR_RC: begin
						cycle <= ~csr_wdata & cycle;
					end
					default: begin
						cycle <= cycle;
					end
				endcase
			end
			else begin
				cycle <= cycle + 1;
			end
		end

	//reg [`MXLEN] mstatus;	//read/write
	/* for all unsupported modes x, xie and xpie can be hardwired to zero, but it doesn't matter */
	wire mstatus_ren = (csr_addr == `CSR_MSTATUS) & csr_rena;
	wire mstatus_wen = (csr_addr == `CSR_MSTATUS) & csr_wena;
	reg [`MXLEN-13-1-1 : 0] mstatus_other;
	wire mstatus_sd = mstatus_other[1 : 0] == 2'b11 | mstatus_other[3 : 2] == 2'b11;
	always
		@(posedge clk) begin
			if(mstatus_wen) begin
				case(csr_op)
					`CSR_RW: begin
						mstatus_other <= csr_wdata[`MXLEN-1-1 : 13];
					end
					`CSR_RS: begin
						mstatus_other <= csr_wdata[`MXLEN-1-1 : 13] | mstatus_other;
					end
					`CSR_RC: begin
						mstatus_other <= ~csr_wdata[`MXLEN-1-1 : 13] & mstatus_other;
					end
					default: begin
						mstatus_other <= mstatus_other;
					end
				endcase
			end
		end

	reg [3 : 0] mstatus_ie;
	always
		@(posedge clk) begin
			if(exception_flag && exception_cause != `MRET) begin		//trap taken
				mstatus_ie <= {1'b0, 1'b0, 1'b0, 1'b0};
			end
			else if(exception_flag && exception_cause == `MRET) begin		//mret
				mstatus_ie <= {mstatus_pie[3], 1'b0, 1'b0, 1'b0};
			end
			else if(mstatus_wen) begin		//exception and mstatus_wen cannot happen in the meantime
				case(csr_op)
					`CSR_RW: begin
						mstatus_ie <= {csr_wdata[3], 1'b0, csr_wdata[1 : 0]};
					end
					`CSR_RS: begin
						mstatus_ie <= {csr_wdata[3], 1'b0, csr_wdata[1 : 0]} | mstatus_ie;
					end
					`CSR_RC: begin
						mstatus_ie <= ~{csr_wdata[3], 1'b0, csr_wdata[1 : 0]} & mstatus_ie;
					end
					default: begin
						mstatus_ie <= mstatus_ie;
					end
				endcase
			end
		end
	
	reg [3 : 0] mstatus_pie;
	always
		@(posedge clk) begin
			if(exception_flag && exception_cause != `MRET) begin		//trap taken
				mstatus_pie <= {mstatus_ie[3], 1'b0, 1'b0, 1'b0};
			end
			else if(exception_flag && exception_cause == `MRET) begin		//mret
				mstatus_pie <= {1'b1, 1'b0, 1'b0, 1'b0};
			end
			else if(mstatus_wen) begin
				case(csr_op)
					`CSR_RW: begin
						mstatus_pie <= {csr_wdata[7], 1'b0, csr_wdata[5 : 4]};
					end
					`CSR_RS: begin
						mstatus_pie <= {csr_wdata[7], 1'b0, csr_wdata[5 : 4]} | mstatus_pie;
					end
					`CSR_RC: begin
						mstatus_pie <= ~{csr_wdata[7], 1'b0, csr_wdata[5 : 4]} & mstatus_pie;
					end
					default: begin
						mstatus_pie <= mstatus_pie;
					end
				endcase
			end
		end	

	reg [4 : 0] mstatus_pp;			//WARL
	always
		@(posedge clk) begin
			if(exception_flag && exception_cause != `MRET) begin		//trap taken
				mstatus_pp <= {2'b11, 1'b0, 1'b0, 1'b0};
			end
			else if(exception_flag && exception_cause == `MRET) begin		//mret
				mstatus_pp <= {2'b00, 1'b0, 1'b0, 1'b0};				//don't support U mode, but for passing the difftest
			end
			else if(mstatus_wen) begin
				case(csr_op)
					`CSR_RW: begin			//only suport M modes
						//mstatus_pp <= {2'b11, 2'b00, 1'b0};
						//mstatus_pp <= {2'b00, 2'b00, 1'b0};
						mstatus_pp <= {csr_wdata[12 : 11], 2'b0, csr_wdata[8]};
					end
					`CSR_RS: begin
						//mstatus_pp <= {2'b00, 2'b00, 1'b0};
						//mstatus_pp <= {2'b11, 2'b00, 1'b0};
						mstatus_pp <= {csr_wdata[12 : 11], 2'b0, csr_wdata[8]} | mstatus_pp;
					end
					`CSR_RC: begin
						//mstatus_pp <= {2'b00, 2'b00, 1'b0};
						//mstatus_pp <= {2'b11, 2'b00, 1'b0};
						mstatus_pp <= ~{csr_wdata[12 : 11], 2'b0, csr_wdata[8]} & mstatus_pp;
					end
					default: begin
						//mstatus_pp <= {2'b00, 2'b00, 1'b0};
						//mstatus_pp <= {2'b11, 2'b00, 1'b0};
						mstatus_pp <= mstatus_pp;
					end
				endcase
			end
		end	
		
	wire [`MXLEN-1-1 : 0] sstatus;		//TODO: wire is not correct
	wire sstatus_sd;		//TODO: wire is not correct
	assign sstatus[14 : 13] = mstatus_other[1 : 0];
	assign sstatus_sd = sstatus[14 : 13] == 2'b11 | sstatus[16 : 15] == 2'b11;

	reg [`MXLEN-1 : 0] mtvec;	
	wire mtvec_ren = (csr_addr == `CSR_MTVEC) & csr_rena;
	wire mtvec_wen = (csr_addr == `CSR_MTVEC) & csr_wena;
	always
		@(posedge clk) begin
			if(mtvec_wen) begin
				case(csr_op)
					`CSR_RW: begin
						mtvec <= csr_wdata;
					end
					`CSR_RS: begin
						mtvec <= csr_wdata | mtvec;
					end
					`CSR_RC: begin
						mtvec <= ~csr_wdata & mtvec;
					end
					default: begin
						mtvec <= mtvec;
					end
				endcase
			end
		end

	reg [`MXLEN-1 : 0] mepc;			//read write
	wire mepc_ren = (csr_addr == `CSR_MEPC) & csr_rena;
	wire mepc_wen = (csr_addr == `CSR_MEPC) & csr_wena;
	always
		@(posedge clk) begin
			if(exception_flag && exception_cause != `MRET) begin		//trap taken
				mepc <= epc;
			end
			else if(mepc_wen) begin
				case(csr_op)
					`CSR_RW: begin
						mepc <= csr_wdata;
					end
					`CSR_RS: begin
						mepc <= csr_wdata | mepc;
					end
					`CSR_RC: begin
						mepc <= ~csr_wdata & mepc;
					end
					default: begin
						mepc <= mepc;
					end
				endcase
			end
		end
	
	//Interrput(1)		ExceptionCode(MXLEN-1)
	reg [`MXLEN-1 : 0] mcause;		//read write
	wire mcause_ren = (csr_addr == `CSR_MCAUSE) & csr_rena;
	wire mcause_wen = (csr_addr == `CSR_MCAUSE) & csr_wena;
	always
		@(posedge clk) begin
			//TODO: ecall from u-mode and s-mode
			if(exception_flag && exception_cause != `MRET) begin		//trap taken
				mcause <= {exception_cause[4], {`MXLEN-5{1'b0}}, exception_cause[3 : 0]};		
			end
			else if(mcause_wen) begin
				case(csr_op)
					`CSR_RW: begin
						mcause <= csr_wdata;
					end
					`CSR_RS: begin
						mcause <= csr_wdata | mcause;
					end
					`CSR_RC: begin
						mcause <= ~csr_wdata & mcause;
					end
					default: begin
						mcause <= mcause;
					end
				endcase
			end
		end

	reg [`MXLEN-1 : 0] mscratch;		//read write
	wire mscratch_ren = (csr_addr == `CSR_MSCRATCH) & csr_rena;
	wire mscratch_wen = (csr_addr == `CSR_MSCRATCH) & csr_wena;
	always
		@(posedge clk) begin
			if(mscratch_wen) begin
				case(csr_op)
					`CSR_RW: begin
						mscratch <= csr_wdata;
					end
					`CSR_RS: begin
						mscratch <= csr_wdata | mscratch;
					end
					`CSR_RC: begin
						mscratch <= ~csr_wdata & mscratch;
					end
					default: begin
						mscratch <= mscratch;
					end
				endcase
			end
		end


	assign csr_data = {64{cycle_ren}} & cycle
					| {64{mstatus_ren}} & {mstatus_sd, mstatus_other, mstatus_pp, mstatus_pie, mstatus_ie}
					| {64{mtvec_ren}} & mtvec
					| {64{mepc_ren}} & mepc
					| {64{mcause_ren}} & mcause
					| {64{mscratch_ren}} & mscratch
					| {64{ie_ren}} & {{52{1'b0}}, eie, tie, sie}
					| {64{ip_ren}} & {{52{1'b0}}, eip, tip, sip};

	assign diff_mstatus = {mstatus_sd, mstatus_other, mstatus_pp, mstatus_pie, mstatus_ie};
	assign diff_mtvec = mtvec;
	assign diff_mcause = mcause;
	assign diff_mepc = mepc;
	assign diff_mscratch = mscratch;
	assign diff_mie = {{52{1'b0}}, eie, tie, sie};
	assign diff_mip = {{52{1'b0}}, eip, tip, sip};
	assign diff_sstatus = {sstatus_sd, sstatus};


endmodule
