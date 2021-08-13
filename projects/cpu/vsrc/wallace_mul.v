`include "defines.v"

module wallace_mul(
    input wire rs1_sign,
    input wire rs2_sign,

    input wire [`REG_BUS] rs1_data,
    input wire [`REG_BUS] rs2_data,

    output wire [127 : 0] mul_result
);
//33 numbers add in the meantime
//actually could be 65bits * 66bits and result is 131bits but we use 132bits result for simplicity
wire [131 : 0] mul_op1 = {{68{rs1_sign & rs1_data[63]}}, rs1_data};		//sign extend
/* booth code */
wire [2 : 0] booth_code[32 : 0];
assign booth_code[0] = {rs2_data[1 : 0], 1'b0};
assign booth_code[32] = {rs2_sign & rs2_data[63], rs2_sign & rs2_data[63], rs2_data[63]};
genvar i; 
generate
        for(i = 1;i < 32;i = i + 1) begin: booth
			assign booth_code[i] = rs2_data[2 * i + 1 : 2 * i - 1];
        end
endgenerate

//p and c
reg [32 : 0] c;
reg [131 : 0] p [32 : 0];
//genvar i; 
generate
        for(i = 0;i < 33;i = i + 1) begin:	booth_decode
			booth2_decode Booth2_decode(.booth2_code(booth_code[i]), .X(mul_op1 << (2 * i)), .cin(c[i]), .Y(p[i]));
        end
endgenerate


//switch
wire [32 : 0] inv_p [131 : 0];
//genvar i; 
generate
        for(i = 0;i < 132;i = i + 1) begin:	switch
			assign inv_p[i] = {p[0][i], p[1][i], p[2][i], p[3][i], p[4][i], p[5][i], p[6][i],
							p[7][i], p[8][i], p[9][i], p[10][i], p[11][i], p[12][i], p[13][i],
							p[14][i], p[15][i], p[16][i], p[17][i], p[18][i], p[19][i], p[20][i],
							p[21][i], p[22][i], p[23][i], p[24][i], p[25][i], p[26][i], p[27][i],
							p[28][i], p[29][i], p[30][i], p[31][i], p[32][i]};
        end
endgenerate


//
//1. 33 to 2
//2. 32 to 2 and the 2 + 1 to 2
//choose plan 1
wire [132 : 0] add_op1;	//131 : 0 is number should be add
wire [131 : 0] add_op2;
wire [131 : 0] add_result;
/* verilator lint_off UNOPTFLAT */
wire [30 : 0] tran_cout [131 : 0]; 
//wire [30 : 0] tran_cin [131 : 0];
assign add_op1[0] = c[31];
//assign tran_cin[0] = c[30 : 0];
wire cin = c[32];
tran33_2 Tran33_2_0(.x(inv_p[0]), .cin(c[30 : 0]), .cout(tran_cout[0]), .c(add_op1[1]), .s(add_op2[0]));
//tran33_2 Tran33_2_1(.x(inv_p[1]), .cin(tran_cout[0]), .cout(tran_cout[1]), .c(add_op1[2]), .s(add_op2[1]));
//tran33_2 Tran33_2_2(.x(inv_p[2]), .cin(tran_cout[1]), .cout(tran_cout[2]), .c(add_op1[3]), .s(add_op2[2]));
//tran33_2 Tran33_2_1(.x(inv_p[1]), .cin(cout[0]), .cout(cout[1]), .c(add_op1[2]), .s(add_op2[1]));
//genvar i; 
/*
generate
        for(i = 1;i < 132;i = i + 1) begin:	Tran_1
			assign tran_cin[i] = tran_cout[i - 1];
        end
endgenerate
*/

generate
        for(i = 1;i < 132;i = i + 1) begin:	Tran
			tran33_2 Tran33_2(.x(inv_p[i]), .cin(tran_cout[i - 1]), .cout(tran_cout[i]), .c(add_op1[i + 1]), .s(add_op2[i]));
        end
endgenerate


assign add_result = add_op1[131 : 0] + add_op2 + cin;
assign mul_result = add_result[127 : 0];

endmodule

