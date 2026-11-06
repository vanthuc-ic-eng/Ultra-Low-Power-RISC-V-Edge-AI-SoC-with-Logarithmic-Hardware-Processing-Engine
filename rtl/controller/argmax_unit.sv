// ============================================================================
// File: argmax_unit.sv
// Project: PULP-inspired Edge AI SoC for Handwritten Digit Recognition
// Module: argmax_unit (2-Stage Pipelined Parallel Binary Tree Argmax)
// Author: Nguyen Van Thuc (24161421)
// Description:
//   2-Stage Pipelined Parallel Binary Tree Argmax Classifier.
//   Stage 1: Computes pair-wise parallel comparisons (0 vs 1) and (2 vs 3)
//            and latches group winner into pipeline registers.
//   Stage 2: Compares group winner against global best logit.
//   Decouples 32-bit carry chains into <= 3.5 ns paths for 100+ MHz sign-off.
//   SystemVerilog IEEE 1800-2012 syntax.
// ============================================================================

`timescale 1ns / 1ps

module argmax_unit (
    input  logic                 clk,
    input  logic                 rst_n,
    input  logic                 clr_i,
    input  logic                 step1_i,     // Stage 1: Latch group winner
    input  logic                 update_i,    // Stage 2: Track cross-group best
    input  logic [1:0]           grp_i,       // 0: 0..3, 1: 4..7, 2: 8..9
    input  logic signed [31:0]   logit0_i,
    input  logic signed [31:0]   logit1_i,
    input  logic signed [31:0]   logit2_i,
    input  logic signed [31:0]   logit3_i,
    output logic [3:0]           best_class_o,
    output logic signed [31:0]   best_logit_o
);

    // ------------------------------------------------------------------------
    // Stage 1: Parallel Binary Tree Pair Comparisons (Combinational)
    // ------------------------------------------------------------------------
    logic signed [31:0] max_01, max_23;
    logic [3:0]         cls_01, cls_23;

    always_comb begin
        // Pair (0, 1) evaluated in parallel with pair (2, 3)
        if (logit1_i > logit0_i) begin
            max_01 = logit1_i;
            cls_01 = {grp_i, 2'd1};
        end else begin
            max_01 = logit0_i;
            cls_01 = {grp_i, 2'd0};
        end

        // Pair (2, 3)
        if (logit3_i > logit2_i) begin
            max_23 = logit3_i;
            cls_23 = {grp_i, 2'd3};
        end else begin
            max_23 = logit2_i;
            cls_23 = {grp_i, 2'd2};
        end
    end

    // Group Winner Selection
    logic signed [31:0] grp_max_logit_comb;
    logic [3:0]         grp_max_class_comb;

    always_comb begin
        if (grp_i == 2'd2) begin
            // For group 2: only classes 8 and 9 are valid (10 and 11 are padding)
            grp_max_logit_comb = max_01;
            grp_max_class_comb = cls_01;
        end else if (max_23 > max_01) begin
            grp_max_logit_comb = max_23;
            grp_max_class_comb = cls_23;
        end else begin
            grp_max_logit_comb = max_01;
            grp_max_class_comb = cls_01;
        end
    end

    // Pipeline Registers between Stage 1 and Stage 2
    logic signed [31:0] grp_max_logit_q;
    logic [3:0]         grp_max_class_q;
    logic [1:0]         grp_id_q;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            grp_max_logit_q <= -32'sd2147483647;
            grp_max_class_q <= 4'd0;
            grp_id_q        <= 2'd0;
        end else if (step1_i) begin
            grp_max_logit_q <= grp_max_logit_comb;
            grp_max_class_q <= grp_max_class_comb;
            grp_id_q        <= grp_i;
        end
    end

    // ------------------------------------------------------------------------
    // Stage 2: Cross-Group Global Maximum Tracking (Pipelined)
    // ------------------------------------------------------------------------
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            best_class_o <= 4'd0;
            best_logit_o <= -32'sd2147483647;
        end else if (clr_i) begin
            best_class_o <= 4'd0;
            best_logit_o <= -32'sd2147483647;
        end else if (update_i) begin
            if (grp_id_q == 2'd0) begin
                best_logit_o <= grp_max_logit_q;
                best_class_o <= grp_max_class_q;
            end else if (grp_max_logit_q > best_logit_o) begin
                best_logit_o <= grp_max_logit_q;
                best_class_o <= grp_max_class_q;
            end
        end
    end

endmodule : argmax_unit
