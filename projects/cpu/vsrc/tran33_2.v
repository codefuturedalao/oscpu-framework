`include "defines.v"

module tran33_2(
	input wire [32 : 0] x,
	input wire [30 : 0] cin,
	
	output wire [30 : 0] cout,		//must keep it in order
	output wire c,
	output wire s
);

/*	S		C		adder

8: 1		1+1		1
7: 2		2		1
6: 2		2+1		2(full+half)
5: 3		3+1		2
4: 5		5		3
3: 7		7+1		5
2: 11		11		7	
1: 33		0		11	

*/	

wire [10 : 0] s1;
wire [10 : 0] c1;

/* level 1 */
genvar i; 
generate
        for(i = 0;i < 11;i = i + 1) begin: level1
			fadder Fadder(.x(x[3 * i]), .y(x[3 * i+1]), .cin(x[3 * i+2]), .s(s1[i]), .c(c1[i]));
        end
endgenerate


/* level 2 */
wire [6 : 0] s2;
wire [6 : 0] c2;
fadder Fadder2_1(.x(s1[0]), .y(s1[1]), .cin(s1[2]), .s(s2[0]), .c(c2[0]));
fadder Fadder2_2(.x(s1[3]), .y(s1[4]), .cin(s1[5]), .s(s2[1]), .c(c2[1]));
fadder Fadder2_3(.x(s1[6]), .y(s1[7]), .cin(s1[8]), .s(s2[2]), .c(c2[2]));
fadder Fadder2_4(.x(s1[9]), .y(s1[10]), .cin(cin[0]), .s(s2[3]), .c(c2[3]));
fadder Fadder2_5(.x(cin[1]), .y(cin[2]), .cin(cin[3]), .s(s2[4]), .c(c2[4]));
fadder Fadder2_6(.x(cin[4]), .y(cin[5]), .cin(cin[6]), .s(s2[5]), .c(c2[5]));
fadder Fadder2_7(.x(cin[7]), .y(cin[8]), .cin(cin[9]), .s(s2[6]), .c(c2[6]));
//cin[10] to next level

/* level 3 */
wire [4 : 0] s3;
wire [4 : 0] c3;

fadder Fadder3_1(.x(s2[0]), .y(s2[1]), .cin(s2[2]), .s(s3[0]), .c(c3[0]));
fadder Fadder3_2(.x(s2[3]), .y(s2[4]), .cin(s2[5]), .s(s3[1]), .c(c3[1]));
fadder Fadder3_3(.x(s2[6]), .y(cin[10]), .cin(cin[11]), .s(s3[2]), .c(c3[2]));
fadder Fadder3_4(.x(cin[12]), .y(cin[13]), .cin(cin[14]), .s(s3[3]), .c(c3[3]));
fadder Fadder3_5(.x(cin[15]), .y(cin[16]), .cin(cin[17]), .s(s3[4]), .c(c3[4]));

/* level 4 */
wire [2 : 0] s4;
wire [2 : 0] c4;
fadder Fadder4_1(.x(s3[0]), .y(s3[1]), .cin(s3[2]), .s(s4[0]), .c(c4[0]));
fadder Fadder4_2(.x(s3[3]), .y(s3[4]), .cin(cin[18]), .s(s4[1]), .c(c4[1]));
fadder Fadder4_3(.x(cin[19]), .y(cin[20]), .cin(cin[21]), .s(s4[2]), .c(c4[2]));
//cin[22] to next level

/* level 5 */
wire [1 : 0] s5;
wire [1 : 0] c5;
fadder Fadder5_1(.x(s4[0]), .y(s4[1]), .cin(s4[2]), .s(s5[0]), .c(c5[0]));
fadder Fadder5_2(.x(cin[22]), .y(cin[23]), .cin(cin[24]), .s(s5[1]), .c(c5[1]));
//cin[25] to next level

/* level 6 */
wire [1 : 0] s6;
wire [1 : 0] c6;
fadder Fadder6_1(.x(s5[0]), .y(s5[1]), .cin(cin[25]), .s(s6[0]), .c(c6[0]));
fadder Fadder6_2(.x(cin[26]), .y(cin[27]), .cin(0), .s(s6[1]), .c(c6[1]));

/* level 7 */
wire s7;
wire c7; 
fadder Fadder7_1(.x(s6[0]), .y(s6[1]), .cin(cin[28]), .s(s7), .c(c7));

/* level 8 */
fadder Fadder8_1(.x(s7), .y(cin[29]), .cin(cin[30]), .s(s), .c(c));

assign cout = {c7, c6, c5, c4, c3, c2, c1};


endmodule
