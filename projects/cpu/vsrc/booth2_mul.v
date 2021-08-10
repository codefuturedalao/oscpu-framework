`include "defines.v"

module booth2_mul(
    input wire clk,
    input wire rst,

    input wire rs1_signed,
    input wire rs2_signed,

    input wire [`REG_BUS] rs1_data,
    input wire [`REG_BUS] rs2_data,
    input wire sel,

    output wire valid,
    output wire [`REG_BUS] mul_result
)

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
wire [65 : 0] mul_op1 = {rs1_signed, rs1_signed, rs1_data};
wire [65 : 0] mul_op2 = {rs2_signed, rs2_signed, rs2_data};

always @(posedge clk) begin
    
end