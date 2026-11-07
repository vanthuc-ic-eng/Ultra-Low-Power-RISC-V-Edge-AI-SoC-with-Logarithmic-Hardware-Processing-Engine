// ============================================================================
// File: compute_engine_1x4.sv
// Project: PULP-inspired Edge AI SoC for Handwritten Digit Recognition
// Module: compute_engine_1x4 (SystemVerilog 1x4 Vector SIMD Engine with Shared Log Encoder)
// Author: Nguyen Van Thuc (24161421)
// Description:
//   Vector Compute Engine with 4 Parallel Processing Elements (1x4 SIMD).
//   Features:
//   1. Single Shared Activation Log Encoder for all 4 PEs (Broadcasted).
//   2. Pre-encoded Log8 Weights (4 x 8-bit = 32-bit bus directly from BRAM).
//   3. Zero Leading-One Detectors (LOD) inside the individual PEs.
//   SystemVerilog implementation using IEEE 1800-2012 syntax.
// ============================================================================

`timescale 1ns / 1ps

module compute_engine_1x4 #(
    parameter int unsigned LOW_W        = 3,
    parameter int unsigned TRUNC_BITS   = 4,
    parameter int unsigned ROUND_MODE   = 1,
    parameter int unsigned ADAPTIVE_LUT = 0,
    parameter int unsigned USE_CARRY    = 1,
    parameter int unsigned QUAD_CURV    = 0
)(
    input  logic                 clk,
    input  logic                 rst_n,
    input  logic                 valid_i,     // Calculation enable
    input  logic                 clr_i,       // Clear / load bias strobe
    input  logic signed [7:0]    act_i,       // Broadcast input activation
    input  logic        [31:0]   weights_i,   // 4 packed 8-bit Log8 weights {w3, w2, w1, w0}
    input  logic signed [127:0]  biases_i,    // 4 packed 32-bit initial biases {b3, b2, b1, b0}
    output logic signed [127:0]  acc_o        // 4 packed 32-bit outputs {acc3, acc2, acc1, acc0}
);

    // 1. Single Shared Input Activation Encoder
    logic                 shared_act_sign;
    logic                 shared_act_zero;
    logic [LOW_W+5:0]     shared_act_log;

    log_act_encoder_u8 #(
        .LOW_W        ( LOW_W        ),
        .ADAPTIVE_LUT ( ADAPTIVE_LUT )
    ) u_shared_act_enc (
        .act_i      ( act_i           ),
        .act_sign_o ( shared_act_sign ),
        .act_zero_o ( shared_act_zero ),
        .act_log_o  ( shared_act_log  )
    );

    // 2. 1x4 Array of Lightweight PEs
    genvar i;
    generate
        for (i = 0; i < 4; i = i + 1) begin : gen_pe
            logic [7:0] w_byte;
            assign w_byte = weights_i[8*i +: 8];

            pe_mac #(
                .LOW_W      ( LOW_W      ),
                .TRUNC_BITS ( TRUNC_BITS ),
                .ROUND_MODE ( ROUND_MODE ),
                .USE_CARRY  ( USE_CARRY  ),
                .QUAD_CURV  ( QUAD_CURV  )
            ) u_pe (
                .clk           ( clk                       ),
                .rst_n         ( rst_n                     ),
                .valid_i       ( valid_i                   ),
                .clr_i         ( clr_i                     ),
                .act_sign_i    ( shared_act_sign           ),
                .act_zero_i    ( shared_act_zero           ),
                .act_log_i     ( shared_act_log            ),
                .weight_sign_i ( w_byte[7]                 ),
                .weight_zero_i ( w_byte == 8'h7F           ),
                .weight_log_i  ( {w_byte[6:4], w_byte[3:0], w_byte[3:2]} ),
                .bias_i        ( biases_i[32*i +: 32]      ),
                .acc_o         ( acc_o[32*i +: 32]         )
            );
        end
    endgenerate

endmodule : compute_engine_1x4
