// ============================================================================
// File: pe_mac.sv
// Project: PULP-inspired Edge AI SoC for Handwritten Digit Recognition
// Module: pe_mac (Ultra-Lightweight SystemVerilog Processing Element)
// Author: Nguyen Van Thuc (24161421)
// Description:
//   Output-stationary Processing Element (PE) receiving pre-encoded log values
//   and accumulating into a 32-bit register.
//   ELIMINATES all Leading-One Detectors (LOD), normalizers, and LUT converters
//   from the individual PE core.
//   SystemVerilog implementation using IEEE 1800-2012 syntax.
// ============================================================================

`timescale 1ns / 1ps

module pe_mac #(
    parameter int unsigned LOW_W        = 3,
    parameter int unsigned TRUNC_BITS   = 4,
    parameter int unsigned ROUND_MODE   = 1,
    parameter int unsigned USE_CARRY    = 1,
    parameter int unsigned QUAD_CURV    = 0
)(
    input  logic                 clk,
    input  logic                 rst_n,
    input  logic                 valid_i,     // MAC enable
    input  logic                 clr_i,       // Clear accumulator / load bias

    // Pre-encoded Activation Input (from Shared Encoder)
    input  logic                 act_sign_i,
    input  logic                 act_zero_i,
    input  logic [LOW_W+5:0]     act_log_i,

    // Pre-encoded Weight Input (directly from BRAM)
    input  logic                 weight_sign_i,
    input  logic                 weight_zero_i,
    input  logic [LOW_W+5:0]     weight_log_i,

    // Initial Bias
    input  logic signed [31:0]   bias_i,

    // 32-bit Accumulated Result
    output logic signed [31:0]   acc_o
);

    // Multiplier output (signed 16-bit)
    logic signed [15:0] prod_w;

    // Instantiate lightweight core multiplier (Zero-LOD, Zero-Normalizer)
    lutalm_core_mul_s8 #(
        .LOW_W      ( LOW_W      ),
        .TRUNC_BITS ( TRUNC_BITS ),
        .ROUND_MODE ( ROUND_MODE ),
        .USE_CARRY  ( USE_CARRY  ),
        .QUAD_CURV  ( QUAD_CURV  )
    ) u_mult_core (
        .sign_a_i ( act_sign_i    ),
        .zero_a_i ( act_zero_i    ),
        .log_a_i  ( act_log_i     ),
        .sign_b_i ( weight_sign_i ),
        .zero_b_i ( weight_zero_i ),
        .log_b_i  ( weight_log_i  ),
        .p_o      ( prod_w        )
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
