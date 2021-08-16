`include "defines.v"

module if_stage(
  	input wire clk,
  	input wire rst,
	input wire if_ready,
	input wire [1 : 0] if_resp,
	input wire [`REG_BUS] new_pc,
  	input wire [`REG_BUS] if_data_read,
	input wire [1 : 0] stall,
  
	output reg if_valid,
	output wire [1 : 0] if_size,
  	output wire [63 : 0] inst_addr,
  	output reg [31:0] inst,
	output reg inst_valid,
 	output wire stall_req
);

reg inst_valid_r;
reg if_valid_r;

wire handshake_done = if_valid_r & if_ready;
//assign if_valid = 1'b1;
assign if_size = `SIZE_W;
assign stall_req = if_valid_r & ~if_ready;
assign inst = if_data_read[31 : 0];
assign if_valid = if_valid_r & ~(inst_valid & (stall == `STALL_KEEP));
assign inst_valid = (if_valid_r & if_ready) | inst_valid_r;

reg [`REG_BUS] pc;

// fetch an instruction
always
	@(posedge clk) begin
  		if(rst == 1'b1) begin
    		pc <= `PC_START;
			if_valid_r <= 1'b1;
			inst_valid_r <= 1'b0;
  		end
 		else begin
			case(stall)
				`STALL_NEXT: begin 
					pc <= new_pc; 
					if_valid_r <= 1'b1;
					inst_valid_r <= 1'b0;
				end
				`STALL_KEEP: begin 
					pc <= pc; 
					if(handshake_done) begin
						if_valid_r <= 1'b0;
						inst_valid_r <= 1'b1;
					end
				end
				`STALL_ZERO: begin pc <= `PC_START; end
				default: begin pc <= `PC_START; end
			endcase
  		end
	end

assign inst_addr = pc;

endmodule
