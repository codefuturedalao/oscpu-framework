`include "defines.v"

module clint(
	input								clk,
	input 								rst,

	input                              valid_i,
    input                              req_i,
    input [63 : 0]            data_write_i,
    input [63 : 0]           addr_i,
    input [7 : 0]       wstrb_i,

	output                             ready_o,
    output reg [63 : 0]        data_read_o,
    output [1:0]                        resp_o,

	output 								time_irq_o,
	output								sip_o
);


	reg [63 : 0] mtime;
	reg [63 : 0] mtimecmp;
	reg [63 : 0] msip;		//why not 64

	assign sip_o = msip[0];
	assign time_irq_o = mtime >= mtimecmp;
	always
		@(posedge clk) begin
			if(rst == 1'b1) begin
				mtime <= 64'b0;
				mtimecmp <= 64'b0;
				msip <= 64'b0;
			end
			else begin
				if(valid_i && req_i && addr_i[15 : 0] == 16'hbff8) begin
					mtime[7 : 0] <= wstrb_i[0] ? data_write_i[7 : 0] : mtime[7 : 0];
					mtime[15 : 8] <= wstrb_i[1] ? data_write_i[15 : 8] : mtime[15 : 8];
					mtime[23 : 16] <= wstrb_i[2] ? data_write_i[23 : 16] : mtime[23 : 16];
					mtime[31 : 24] <= wstrb_i[3] ? data_write_i[31 : 24] : mtime[31 : 24];
					mtime[39 : 32] <= wstrb_i[4] ? data_write_i[39 : 32] : mtime[39 : 32];
					mtime[47 : 40] <= wstrb_i[5] ? data_write_i[47 : 40] : mtime[47 : 40];
					mtime[55 : 48] <= wstrb_i[6] ? data_write_i[55 : 48] : mtime[55 : 48];
					mtime[63 : 56] <= wstrb_i[7] ? data_write_i[63 : 56] : mtime[63 : 56];
				end
				else begin
					mtime <= mtime + 1;
				end

				if(valid_i && req_i && addr_i[15 : 0] == 16'h4000) begin
					mtimecmp[7 : 0] <= wstrb_i[0] ? data_write_i[7 : 0] : mtimecmp[7 : 0];
					mtimecmp[15 : 8] <= wstrb_i[1] ? data_write_i[15 : 8] : mtimecmp[15 : 8];
					mtimecmp[23 : 16] <= wstrb_i[2] ? data_write_i[23 : 16] : mtimecmp[23 : 16];
					mtimecmp[31 : 24] <= wstrb_i[3] ? data_write_i[31 : 24] : mtimecmp[31 : 24];
					mtimecmp[39 : 32] <= wstrb_i[4] ? data_write_i[39 : 32] : mtimecmp[39 : 32];
					mtimecmp[47 : 40] <= wstrb_i[5] ? data_write_i[47 : 40] : mtimecmp[47 : 40];
					mtimecmp[55 : 48] <= wstrb_i[6] ? data_write_i[55 : 48] : mtimecmp[55 : 48];
					mtimecmp[63 : 56] <= wstrb_i[7] ? data_write_i[63 : 56] : mtimecmp[63 : 56];
				end

				if(valid_i && req_i && addr_i[15 : 0] == 16'h0000) begin
					msip[0]	<= wstrb_i[0] ? data_write_i[0] : msip[0];
				end

			end
		end				

		

	assign	data_read_o = {64{(addr_i[15 : 0] == 16'hbff8)}} & mtime
				  |{64{(addr_i[15 : 0] == 16'h4000)}} & mtimecmp
				  |{64{(addr_i[15 : 0] == 16'h0000)}} & msip;

	assign ready_o	= 1'b1;
	assign resp_o  = 2'b00;



endmodule
