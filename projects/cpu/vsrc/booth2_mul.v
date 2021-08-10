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