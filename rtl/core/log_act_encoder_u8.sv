// ============================================================================
// File: log_act_encoder_u8.sv
// Project: PULP-inspired Edge AI SoC for Handwritten Digit Recognition
// Module: log_act_encoder_u8 (Shared Input Activation Logarithmic Encoder)
// Author: Nguyen Van Thuc (24161421)
// Description:
//   Single shared logarithmic encoder for input activations.
//   Mã hóa 1 lần duy nhất cho điểm ảnh / kích hoạt tầng ẩn rồi phát (broadcast)
//   đến cả 4 Processing Elements (1x4 SIMD Engine).
//   Output: 11-bit packed bundle: {sign, zero, log[8:0]}.
//   SystemVerilog implementation using IEEE 1800-2012 syntax.
// ============================================================================

`timescale 1ns / 1ps

module log_act_encoder_u8 #(
    parameter int unsigned LOW_W        = 3,
    parameter int unsigned ADAPTIVE_LUT = 0
)(
    input  logic signed [7:0]    act_i,
    output logic                 act_sign_o,
    output logic                 act_zero_o,
    output logic [LOW_W+5:0]     act_log_o
);

    logic [7:0] mag_w;

    // 1. Sign and Magnitude Extraction
    log_input_sign_u8 u_sign (
        .data_i ( act_i      ),
        .mag_o  ( mag_w      ),
        .sign_o ( act_sign_o ),
        .zero_o ( act_zero_o )
    );

    // 2. Normalization & LUT logarithmic conversion
    log_encoder_u8 #(
        .LOW_W        ( LOW_W        ),
        .ADAPTIVE_LUT ( ADAPTIVE_LUT )
    ) u_encoder (
        .mag_i ( mag_w      ),
        .log_o ( act_log_o  )
    );

endmodule : log_act_encoder_u8
