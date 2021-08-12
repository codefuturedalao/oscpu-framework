`include "defines.v"

module multiCycle_div(
    input wire clk,
    input wire rst,
    input wire valid,

    input wire div_sign,
	input wire div_32,

    input wire [`REG_BUS] rs1_data,
    input wire [`REG_BUS] rs2_data,

    output wire ready,
    output wire [127 : 0] div_result
);



/*


			init: high_of_rs1_data	init: low_of_rs1_data
			final: rem				final: quot
 ----->[		REM			][		quot		]			//shift left 1 bits per clock
 |				 |	
 |				 |	
 |				 |									[		rs2_data		]
 |				 |												|	
 |				 |												|	
 |				 |												|	
 |				 |											not	/  keep	
 |				 |												|	
 |				 |												|	
 |				 |												|	
 |			------------------------------------------------------------
 |			|														   |
 |			|														   |
 |			|						Adder							   |
 |			|														   |
 |			|														   |
 |			------------------------------------------------------------
 |										|						
 |										|						
 |										|						
	-------------------------------------


*/
//sign extend !!!!

reg [6 : 0] counter;
reg	[64 : 0] rem;
reg [64 : 0] quot;
reg shift_bit;
reg [64 : 0] rs1_data_r;
reg [64 : 0] rs2_data_r;

wire [64 : 0] div_op1;
wire [64 : 0] div_op2;

assign div_op1 = (counter == 7'b000_0000) ? (div_32 ? {{33{div_sign & rs1_data[31]}}, rs1_data[31 : 0]} :{div_sign & rs1_data[63], rs1_data[63 : 0]}) : rs1_data_r;
assign div_op2 = (counter == 7'b000_0000) ? (div_32 ? {{33{div_sign & rs2_data[31]}}, rs2_data[31 : 0]} :{div_sign & rs2_data[63], rs2_data[63 : 0]}) : rs2_data_r;
//assign div_op2 = (counter == 7'b000_0000) ? {div_sign & rs2_data[63], rs2_data[63 : 0]} : rs1_data_r;

wire [64 : 0] add_op1;
wire [64 : 0] add_op2;
wire cin;
wire [64 : 0] add_result;

wire add_or_sub;
assign add_or_sub = (counter == 7'b000_0000) ? (div_op1[64] ^ div_op2[64]) : (shift_bit ^ div_op2[64]);
assign add_op1 = (~rst & valid) ?
		((counter == 7'b0) ? {65{div_op1[64]}} : rem)
		:	65'b0;

assign add_op2 = (~rst & valid) ?
		((add_or_sub == 1'b1) ? div_op2 : ~div_op2)
		:   65'b0;

assign cin = ~add_or_sub;
assign add_result = add_op1 + add_op2 + cin;

wire [64 : 0] rem_next = {add_result[63 : 0], (counter == 7'b0) ? div_op1[64] : quot[64]};
wire [64 : 0] quot_next = {((counter == 7'b0) ? div_op1[63 : 0] : quot[63 : 0]),  ~(add_result[64] ^ div_op2[64])};
wire shift_bit_next = add_result[64];

/* output */
//No-restore signed division
/* divide zero */
// DIVU		REMU		DIV		REM
// all 1	rs1			-1		rs1 			
wire div_zero;
assign div_zero= ~(|div_op2);
/* divide trap */
//	100000... / 111111...
wire overflow;
assign overflow = div_32 ? (&div_op1[63 : 31] & ~(|div_op1[30 : 0]) & (&div_op2[31 : 0])) :
		div_op1[63] & ~(|div_op1[62 : 0]) & (&div_op2[63 : 0]) & div_sign;

assign ready = (counter == 7'd66) | (valid & (overflow | div_zero));
//fix
//TODO: set wire ~div_op2
wire [127 : 0] overflow_result = div_32 ? {64'b0, {32{1'b1}}, 1'b1, 31'b0} : {64'b0, 1'b1, 63'b0};
wire [127 : 0] div_zero_result = div_32 ? {32'b0, div_op1[31 : 0], 32'b0, {32{1'b1}}} : {div_op1[63 : 0], {64{1'b1}}};

wire [64 : 0] fix_quot = (div_op1[64] ^ div_op2[64]) ? (((~div_32 & (quot[63] & ~(|quot[62 : 0]))) | (div_32 & (&quot[63 : 31]) & ~(|quot[30 : 0]))) ? quot[64 : 0] : quot[64 : 0] + 1) : quot[64 : 0];
wire [64 : 0] fix_rem = (rem[64] ^ div_op1[64]) ? ((div_op1[64] ^ div_op2[64]) ? (rem + (~div_op2) + 1) : (rem + div_op2)) : rem;
assign div_result = overflow ? overflow_result : (div_zero ?  div_zero_result : {fix_rem[63 : 0], fix_quot[63 : 0]});

always
	@(posedge clk) begin
		if(rst == 1'b1) begin
			counter <= 7'b000_0000;
			rem <= 65'b0;
			quot <= 65'b0;
			shift_bit <= 1'b0;
		end
		else begin
			if(valid) begin
				if(counter == 7'b000_0000) begin
					rs1_data_r <= (div_32 ? {{33{div_sign & rs1_data[31]}}, rs1_data[31 : 0]} : {div_sign & rs1_data[63], rs1_data});
					rs2_data_r <= (div_32 ? {{33{div_sign & rs2_data[31]}}, rs2_data[31 : 0]} : {div_sign & rs2_data[63], rs2_data});
				end
				if(counter == 7'd66 || div_zero || overflow) begin
					counter <= 7'b000_0000;
					rem <= 65'b0;
					quot <= 65'b0;
					shift_bit <= 1'b0;
				end
				else begin
					counter <= counter + 1;
					rem <= rem_next;
					quot <= quot_next;
					shift_bit <= shift_bit_next;
				end
			end
		end
	end



endmodule
