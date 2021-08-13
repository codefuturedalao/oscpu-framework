`include "defines.v"

module booth2_mul(
    input wire clk,
    input wire rst,
    input wire valid,

    input wire rs1_sign,
    input wire rs2_sign,

    input wire [`REG_BUS] rs1_data,
    input wire [`REG_BUS] rs2_data,

    output wire ready,
    output wire [127 : 0] mul_result
);

// calculate {rs1_signed, rs1_data} * {rs2_signed, rs2_data}
/*

            init:  0            init: rs2
            final: high64       high: high64
   ---> [       hi      ] [         lo      ]       //shift 2 bits per clock 
   |             |
   |             |                        [       rs1_data        ]
   |             |                                   |
   |             |                                   |
   |             |                            |               |
   |             |                            |    Booth2     |
   |             |                            |               | 
   |             |                                   |
   |         ---------------------------------------------
   |         |                                           |
   |         |                                           |
   |         |                 Adder                     |
   |         |                                           |
   |         |                                           |
   |         ---------------------------------------------
   |                             |
   |                             |
   |                             |
    -----------------------------

  rs2_data:      yi+1        yi      yi-1
                   0          0         0       0
                   0          0         1       +X
                   0          1         0       +X
                   0          1         1       +2X
                   1          0         0       -2X
                   1          0         1       -X
                   1          1         0       -X
                   1          1         1       0
*/
/* combine the unsigned mul with signed mul with 0 extend */
reg [6 : 0] counter;
reg [64 : 0] hi_r;
reg [64 : 0] lo_r;
reg shift_bit;
//use reg instead of wire becaouse rs1_data change during 32 cycles
reg [64 : 0] rs1_data_r;
reg [64 : 0] rs2_data_r;
wire [64 : 0] mul_op1 = (counter == 7'b000_0000) ? {rs1_sign & rs1_data[63], rs1_data} : {rs1_data_r};
wire [64 : 0] mul_op2 = (counter == 7'b000_0000) ? {rs2_sign & rs2_data[63], rs2_data} : {rs2_data_r};
wire [2 : 0] booth_code;

/* 67 bits adder */
wire [66 : 0] add_op1;
wire [66 : 0] add_op2;
wire [66 : 0] add_result;       //for simplity, use + in Mul module instead of ALU
wire cin;

assign booth_code = (~rst & valid) ? 
        ((counter == 7'b0) ? {rs2_data[1 : 0], 1'b0} : 
        ((counter == 7'd32) ? {mul_op2[64], lo_r[0], shift_bit} : {lo_r[1 : 0], shift_bit} )) 
        : 3'b000;
assign add_op1 = (~rst & valid) ? 
        ((counter == 7'b0) ? 67'b0 : {hi_r[64], hi_r[64], hi_r}) 
        : 67'b0;


assign add_op2 = ({67{booth_code == 3'b001 | booth_code == 3'b010}} & {mul_op1[64], mul_op1[64], mul_op1})
            |    ({67{booth_code == 3'b011}} & {mul_op1[64], mul_op1, 1'b0})
            |    ({67{booth_code == 3'b100}} & {~mul_op1[64], ~mul_op1, 1'b1})
            |    ({67{booth_code == 3'b101 | booth_code == 3'b110}} & {~mul_op1[64], ~mul_op1[64], ~mul_op1});

assign cin = booth_code[2] & ~(&booth_code);
assign add_result = add_op1 + add_op2 + cin;


wire [64 : 0] hi_r_next = add_result[66 : 2];
wire [64 : 0] lo_r_next = {add_result[1 : 0],
            (counter == 7'b0) ? mul_op2[64 : 2] : lo_r[64 : 2]};
wire shift_bit_next = (counter == 7'b0) ? mul_op2[1] : lo_r[1];

/* output */
assign ready = (counter == 7'd33);
assign mul_result = {hi_r[61 : 0], lo_r, shift_bit};

always @(posedge clk) begin
    if(rst == 1'b1) begin
        counter <= 7'b000_0000; 
        hi_r <= 65'b0;
        lo_r <= 65'b0;
        shift_bit <= 1'b0; 
    end 
    else begin
        if(valid) begin     //valid need keep 33 cycle
            if(counter == 7'b000_0000) begin
                rs1_data_r <= {rs1_sign & rs1_data[63], rs1_data};
                rs2_data_r <= {rs2_sign & rs2_data[63], rs2_data};
            end
            if(counter == 7'd33) begin
                counter <= 7'b000_0000;
                hi_r <= 65'b0;
                lo_r <= 65'b0;
                shift_bit <= 1'b0; 
            end
            else begin
                counter <= counter + 1;  
                hi_r <= hi_r_next;
                lo_r <= lo_r_next;
                shift_bit <= shift_bit_next; 
            end
        end
    end
end


endmodule
