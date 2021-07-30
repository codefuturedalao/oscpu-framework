
//--xuezhen--

`include "defines.v"

module if_stage(
  	input wire clk,
  	input wire rst,
	input wire [`REG_BUS] new_pc,
  
  output wire [63 : 0]inst_addr,
  output wire         inst_ena
  
);

reg [`REG_BUS]pc;

// fetch an instruction
always@( posedge clk )
begin
  if( rst == 1'b1 )
  begin
    pc <= `PC_START;
  end
  else
  begin
    pc <= new_pc;
  end
end

assign inst_addr = pc;
assign inst_ena  = ( rst == 1'b1 ) ? 0 : 1;


endmodule
