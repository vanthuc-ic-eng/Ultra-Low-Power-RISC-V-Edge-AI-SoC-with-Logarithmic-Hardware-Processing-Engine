// ============================================================================
// File: argmax_unit.sv
// Project: PULP-inspired Edge AI SoC for Handwritten Digit Recognition
// Module: argmax_unit (SystemVerilog Parallel Argmax Classifier)
// Author: Nguyen Van Thuc (24161421)
// Description:
//   Single-cycle parallel argmax unit tracking the highest logit across all
//   10 handwritten digit classes (0-9).
//   SystemVerilog implementation using IEEE 1800-2012 syntax.
// ============================================================================

`timescale 1ns / 1ps

module argmax_unit (
    input  logic                 clk,
    input  logic                 rst_n,
    input  logic                 clr_i,
    input  logic                 update_i,
    input  logic [1:0]           grp_i,       // 0: 0..3, 1: 4..7, 2: 8..9
    input  logic signed [31:0]   logit0_i,
    input  logic signed [31:0]   logit1_i,
    input  logic signed [31:0]   logit2_i,
    input  logic signed [31:0]   logit3_i,
    output logic [3:0]           best_class_o,
    output logic signed [31:0]   best_logit_o
);

    // Local group maximum calculation
    logic signed [31:0] grp_max_logit;
    logic [3:0]         grp_max_class;

    always_comb begin
        case (grp_i)
            2'd0: begin // Classes 0, 1, 2, 3
                grp_max_logit = logit0_i;
                grp_max_class = 4'd0;
                if (logit1_i > grp_max_logit) begin
                    grp_max_logit = logit1_i;
                    grp_max_class = 4'd1;
                end
                if (logit2_i > grp_max_logit) begin
                    grp_max_logit = logit2_i;
                    grp_max_class = 4'd2;
                end
                if (logit3_i > grp_max_logit) begin
                    grp_max_logit = logit3_i;
                    grp_max_class = 4'd3;
                end
            end

            2'd1: begin // Classes 4, 5, 6, 7
                grp_max_logit = logit0_i;
                grp_max_class = 4'd4;
                if (logit1_i > grp_max_logit) begin
                    grp_max_logit = logit1_i;
                    grp_max_class = 4'd5;
                end
                if (logit2_i > grp_max_logit) begin
                    grp_max_logit = logit2_i;
                    grp_max_class = 4'd6;
                end
                if (logit3_i > grp_max_logit) begin
                    grp_max_logit = logit3_i;
                    grp_max_class = 4'd7;
                end
            end

            2'd2: begin // Classes 8, 9 (10 and 11 ignored)
                grp_max_logit = logit0_i;
                grp_max_class = 4'd8;
                if (logit1_i > grp_max_logit) begin
                    grp_max_logit = logit1_i;
                    grp_max_class = 4'd9;
                end
            end

            default: begin
                grp_max_logit = -32'sd2147483647;
                grp_max_class = 4'd0;
            end
        endcase
    end

    // Sequential tracking across groups
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            best_class_o <= 4'd0;
            best_logit_o <= -32'sd2147483647;
        end else if (clr_i) begin
            best_class_o <= 4'd0;
            best_logit_o <= -32'sd2147483647;
        end else if (update_i) begin
            if (grp_i == 2'd0) begin
                best_logit_o <= grp_max_logit;
                best_class_o <= grp_max_class;
            end else if (grp_max_logit > best_logit_o) begin
                best_logit_o <= grp_max_logit;
                best_class_o <= grp_max_class;
            end
        end
    end

endmodule : argmax_unit
