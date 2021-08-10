`include "defines.v"
module decoder5_32(
    input wire [4 : 0] in,
    output wire [31 : 0] out
);
    assign out[0] = (in == 5'b00000);
    assign out[1] = (in == 5'b00001);
    assign out[2] = (in == 5'b00010);
    assign out[3] = (in == 5'b00011);
    assign out[4] = (in == 5'b00100);
    assign out[5] = (in == 5'b00101);
    assign out[6] = (in == 5'b00110);
    assign out[7] = (in == 5'b00111);
    assign out[8] = (in == 5'b01000);
    assign out[9] = (in == 5'b01001);
    assign out[10] = (in == 5'b01010);
    assign out[11] = (in == 5'b01011);
    assign out[12] = (in == 5'b01100);
    assign out[13] = (in == 5'b01101);
    assign out[14] = (in == 5'b01110);
    assign out[15] = (in == 5'b01111);
    assign out[16] = (in == 5'b10000);
    assign out[17] = (in == 5'b10001);
    assign out[18] = (in == 5'b10010);
    assign out[19] = (in == 5'b10011);
    assign out[20] = (in == 5'b10100);
    assign out[21] = (in == 5'b10101);
    assign out[22] = (in == 5'b10110);
    assign out[23] = (in == 5'b10111);
    assign out[24] = (in == 5'b11000);
    assign out[25] = (in == 5'b11001);
    assign out[26] = (in == 5'b11010);
    assign out[27] = (in == 5'b11011);
    assign out[28] = (in == 5'b11100);
    assign out[29] = (in == 5'b11101);
    assign out[30] = (in == 5'b11110);
    assign out[31] = (in == 5'b11111);

endmodule