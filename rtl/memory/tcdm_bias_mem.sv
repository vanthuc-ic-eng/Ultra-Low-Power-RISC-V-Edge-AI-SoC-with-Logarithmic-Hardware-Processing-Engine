// ============================================================================
// File: tcdm_bias_mem.sv
// Project: PULP-inspired Edge AI SoC for Handwritten Digit Recognition
// Module: tcdm_bias_mem (SystemVerilog TCDM Bias Storage)
// Author: Nguyen Van Thuc (24161421)
// Description:
//   Bias storage for Layer 1 (64 x 32-bit) and Layer 2 (12 x 32-bit).
//   Provides parallel 128-bit output (4 x 32-bit biases) for direct single-cycle
//   loading into the 4 Processing Elements.
//   SystemVerilog implementation using IEEE 1800-2012 syntax.
// ============================================================================

`timescale 1ns / 1ps

module tcdm_bias_mem #(
    parameter BIAS_L1_FILE = "",
    parameter BIAS_L2_FILE = ""
)(
    input  logic         clk,
    input  logic [3:0]   l1_grp_i,      // Group 0..15
    output logic [127:0] l1_biases_o,   // 4 packed 32-bit biases {b3, b2, b1, b0}

    input  logic [1:0]   l2_grp_i,      // Group 0..2
    output logic [127:0] l2_biases_o    // 4 packed 32-bit biases {b3, b2, b1, b0}
);

    logic [31:0] mem_l1 [0:63];
    logic [31:0] mem_l2 [0:11];

    initial begin
        for (int i = 0; i < 64; i++) mem_l1[i] = 32'sd0;
        for (int i = 0; i < 12; i++) mem_l2[i] = 32'sd0;
        if (BIAS_L1_FILE != "") begin
            $readmemh(BIAS_L1_FILE, mem_l1);
        end
        if (BIAS_L2_FILE != "") begin
            $readmemh(BIAS_L2_FILE, mem_l2);
        end
    end

    // Combinational parallel 128-bit read
    assign l1_biases_o = {
        mem_l1[{l1_grp_i, 2'b11}],
        mem_l1[{l1_grp_i, 2'b10}],
        mem_l1[{l1_grp_i, 2'b01}],
        mem_l1[{l1_grp_i, 2'b00}]
    };

    assign l2_biases_o = {
        mem_l2[{l2_grp_i, 2'b11}],
        mem_l2[{l2_grp_i, 2'b10}],
        mem_l2[{l2_grp_i, 2'b01}],
        mem_l2[{l2_grp_i, 2'b00}]
    };

endmodule : tcdm_bias_mem
