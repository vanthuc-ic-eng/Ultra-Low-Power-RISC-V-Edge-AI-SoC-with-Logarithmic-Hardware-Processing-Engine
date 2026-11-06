// ============================================================================
// File: lutalm_core_mul_s8.sv
// Project: PULP-inspired Edge AI SoC for Handwritten Digit Recognition
// Module: lutalm_core_mul_s8 (Ultra-Lightweight Pre-Encoded Log Multiplier Core)
// Author: Nguyen Van Thuc (24161421)
// Description:
//   Core approximate logarithmic multiplier accepting pre-encoded inputs.
//   Both activation and weight are already in logarithmic representation
//   {sign, zero, log[LOW_W+5:0]}.
//   ELIMINATES all Leading-One Detectors (LOD), normalizers, and LUT converters
//   from the critical PE datapath.
//   SystemVerilog implementation using IEEE 1800-2012 syntax.
// ============================================================================

`timescale 1ns / 1ps

module lutalm_core_mul_s8 #(
    parameter int unsigned LOW_W        = 3,
    parameter int unsigned TRUNC_BITS   = 4,
    parameter int unsigned ROUND_MODE   = 1,
    parameter int unsigned USE_CARRY    = 1,
    parameter int unsigned QUAD_CURV    = 0
)(
    // Pre-encoded Activation Input
    input  logic                 sign_a_i,
    input  logic                 zero_a_i,
    input  logic [LOW_W+5:0]     log_a_i,

    // Pre-encoded Weight Input
    input  logic                 sign_b_i,
    input  logic                 zero_b_i,
    input  logic [LOW_W+5:0]     log_b_i,

    // 16-bit Signed Product
    output logic signed [15:0]   p_o
);

    logic [LOW_W+6:0] log_sum_w;
    logic [15:0]      approx_mag_w;

    // 1. Logarithmic Domain Adder
    generate
        if (USE_CARRY) begin : gen_carry_adder
            log_adder_u8 #(
                .LOW_W     ( LOW_W                  )
            ) u_log_add (
                .log_a_i   ( log_a_i                ),
                .log_b_i   ( log_b_i                ),
                .log_sum_o ( log_sum_w              )
            );
        end else begin : gen_lut_adder
            lut_adder_n #(
                .WIDTH     ( LOW_W + 6              )
            ) u_log_add (
                .a         ( log_a_i                ),
                .b         ( log_b_i                ),
                .sum       ( log_sum_w              )
            );
        end
    endgenerate

    // 2. Antilogarithm Converter (Shift mantissa by exponent)
    log_antilog_u16 #(
        .LOW_W             ( LOW_W                  ),
        .QUAD_CURV         ( QUAD_CURV              )
    ) u_antilog (
        .log_sum_i         ( log_sum_w              ),
        .product_o         ( approx_mag_w           )
    );

    // 3. Output Sign and Zero Detection
    logic sign_prod_w;
    logic zero_prod_w;

    assign sign_prod_w = sign_a_i ^ sign_b_i;
    assign zero_prod_w = zero_a_i | zero_b_i;

    // 4. Zero-fused Pre-adder & Carry Rounding Truncation
    localparam int unsigned REM_BITS = 16 - TRUNC_BITS;
    logic round_bit;
    logic [REM_BITS-1:0] raw_trunc_w;
    logic eff_sign_w;
    logic eff_round_w;
    logic [REM_BITS-1:0] eff_raw_w;
    logic carry_in;
    logic [REM_BITS-1:0] base_w;
    logic [REM_BITS-1:0] signed_mag_w;

    assign round_bit   = (ROUND_MODE && (TRUNC_BITS > 0)) ? approx_mag_w[TRUNC_BITS - 1] : 1'b0;
    assign raw_trunc_w = approx_mag_w[15:TRUNC_BITS];

    assign eff_sign_w  = sign_prod_w & ~zero_prod_w;
    assign eff_round_w = round_bit & ~zero_prod_w;
    assign eff_raw_w   = zero_prod_w ? {REM_BITS{1'b0}} : raw_trunc_w;
    assign carry_in    = eff_sign_w ? ~eff_round_w : eff_round_w;
    assign base_w      = eff_sign_w ? ~eff_raw_w : eff_raw_w;

    generate
        if (USE_CARRY) begin : gen_carry_round
            assign signed_mag_w = base_w + carry_in;
        end else begin : gen_lut_round
            lut_inc_n #(
                .WIDTH ( REM_BITS                   )
            ) u_inc (
                .a     ( base_w                     ),
                .cin   ( carry_in                   ),
                .sum   ( signed_mag_w               )
            );
        end
    endgenerate

    assign p_o = {signed_mag_w, {TRUNC_BITS{1'b0}}};

endmodule : lutalm_core_mul_s8
