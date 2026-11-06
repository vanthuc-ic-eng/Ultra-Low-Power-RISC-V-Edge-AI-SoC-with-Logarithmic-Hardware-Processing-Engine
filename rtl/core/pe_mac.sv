// ============================================================================
// File: pe_mac.sv
// Project: PULP-inspired Edge AI SoC for Handwritten Digit Recognition
// Module: pe_mac (SystemVerilog Processing Element)
// Author: Nguyen Van Thuc (24161421)
// Description:
//   Output-stationary Processing Element (PE) integrating the custom
//   approximate logarithmic multiplier (lutalm_mul_s8) with a 32-bit accumulator.
//   SystemVerilog implementation using IEEE 1800-2012 syntax.
// ============================================================================

`timescale 1ns / 1ps

module pe_mac #(
    parameter int unsigned LOW_W        = 3,
    parameter int unsigned TRUNC_BITS   = 4,
    parameter int unsigned ROUND_MODE   = 1,
    parameter int unsigned ADAPTIVE_LUT = 0,
    parameter int unsigned USE_CARRY    = 1,
    parameter int unsigned QUAD_CURV    = 0
)(
    input  logic signed [7:0]  act_i,       // 8-bit signed activation (input)
    input  logic signed [7:0]  weight_i,    // 8-bit signed weight
    input  logic signed [31:0] bias_i,      // 32-bit initial bias to load
    input  logic               valid_i,     // MAC enable
    input  logic               clr_i,       // Clear accumulator / load bias
    input  logic               clk,         // Clock
    input  logic               rst_n,       // Active-low asynchronous reset
    output logic signed [31:0] acc_o        // 32-bit accumulated sum
);

    // Multiplier output (signed 16-bit)
    logic signed [15:0] prod_w;

    // Instantiate custom approximate logarithmic multiplier
    lutalm_mul_s8 #(
        .LOW_W(LOW_W),
        .TRUNC_BITS(TRUNC_BITS),
        .ROUND_MODE(ROUND_MODE),
        .ADAPTIVE_LUT(ADAPTIVE_LUT),
        .USE_CARRY(USE_CARRY),
        .QUAD_CURV(QUAD_CURV)
    ) u_mult (
        .a_i(act_i),
        .b_i(weight_i),
        .p_o(prod_w)
    );

    // 32-bit Accumulator logic (SystemVerilog always_ff)
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            acc_o <= 32'sd0;
        end else if (clr_i) begin
            acc_o <= bias_i;
        end else if (valid_i) begin
            acc_o <= acc_o + 32'(signed'(prod_w));
        end
    end

endmodule : pe_mac
