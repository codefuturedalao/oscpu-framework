`include "defines.v"

module if_stage(
  	input wire clk,
  	input wire rst,
	input wire [`REG_BUS] new_pc,
	input wire [1 : 0] stall,
  
  	output wire [63 : 0]inst_addr,
  	output wire         inst_ena
  
);

reg [`REG_BUS]pc;

// fetch an instruction
always
	@(posedge clk) begin
  		if(rst == 1'b1) begin
    		pc <= `PC_START;
  		end
 		else begin
			case(stall)
				`STALL_NEXT: begin pc <= new_pc; end
				`STALL_KEEP: begin pc <= pc; end
				`STALL_ZERO: begin pc <= `PC_START; end
				default: begin pc<= `PC_START; end
			endcase
  		end
	end

assign inst_addr = pc;
assign inst_ena  = ( rst == 1'b1 ) ? 0 : 1;

endmodule
