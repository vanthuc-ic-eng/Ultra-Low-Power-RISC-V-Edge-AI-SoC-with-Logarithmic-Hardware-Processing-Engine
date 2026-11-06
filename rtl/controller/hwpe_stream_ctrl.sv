// ============================================================================
// File: hwpe_stream_ctrl.sv
// Project: PULP-inspired Edge AI SoC for Handwritten Digit Recognition
// Module: hwpe_stream_ctrl (SystemVerilog Autonomous Stream Controller)
// Author: Nguyen Van Thuc (24161421)
// Description:
//   Autonomous HWPE Stream Controller & Address Generation Unit (AGU).
//   Pipelined synchronous BRAM streaming with zero-cycle overhead.
//   SystemVerilog implementation using IEEE 1800-2012 syntax and typed enums.
// ============================================================================

`timescale 1ns / 1ps

import pulp_hwpe_pkg::*;

module hwpe_stream_ctrl #(
    parameter int unsigned L1_INPUT_DIM  = pulp_hwpe_pkg::L1_INPUT_DIM,
    parameter int unsigned L1_NEURONS    = pulp_hwpe_pkg::L1_NEURONS,
    parameter int unsigned L2_NEURONS    = pulp_hwpe_pkg::L2_NEURONS,
    parameter int unsigned SHIFT_BITS    = pulp_hwpe_pkg::SHIFT_BITS
)(
    input  logic                 clk,
    input  logic                 rst_n,

    // Host Control Interface
    input  logic                 start_i,
    output logic                 busy_o,
    output logic                 done_o,
    output logic [31:0]          cycle_count_o,

    // Weight TCDM Interface
    output logic [13:0]          w_addr_o,

    // Activation TCDM Interface
    output logic [9:0]           l1_in_addr_o,
    output logic                 l1_wb_we_o,
    output logic [5:0]           l1_wb_addr_o,
    output logic [5:0]           l2_in_addr_o,

    // Bias TCDM Interface
    output logic [3:0]           l1_bias_grp_o,
    output logic [1:0]           l2_bias_grp_o,

    // PE Array Control
    output logic                 pe_clr_o,
    output logic                 pe_valid_o,
    output logic                 pe_sel_l2_o, // 0: L1 inputs, 1: L2 inputs

    // Argmax Control (2-stage pipelined timing sign-off)
    output logic                 argmax_clr_o,
    output logic                 argmax_step1_o,
    output logic                 argmax_update_o,
    output logic [1:0]           argmax_grp_o
);

    // FSM States using typed enum from pulp_hwpe_pkg
    fsm_state_e state_q, state_d;

    // Loop counters
    logic [3:0] l1_grp_q;     // 0..15 (16 groups of 4 = 64 neurons)
    logic [9:0] l1_k_q;       // 0..783
    logic [1:0] l2_grp_q;     // 0..2 (3 groups of 4 = 12 neurons)
    logic [5:0] l2_k_q;       // 0..63
    logic [1:0] l2_drain_step_q; // 3-cycle pipelined drain for MAC & argmax timing sign-off

    // 1-cycle pipeline delay for synchronous BRAM read
    logic stream_valid_pipe;

    // Combinational Argmax Controls (2-stage pipelined)
    assign argmax_step1_o  = (state_q == ST_L2_DRAIN && (l2_drain_step_q == 2'd1));
    assign argmax_update_o = (state_q == ST_L2_DRAIN && (l2_drain_step_q == 2'd2));
    assign argmax_grp_o    = l2_grp_q;
    assign argmax_clr_o    = (state_q == ST_IDLE && start_i);

    // Cycle counter (always_ff)
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            cycle_count_o <= 32'd0;
        end else if (start_i && state_q == ST_IDLE) begin
            cycle_count_o <= 32'd0;
        end else if (busy_o) begin
            cycle_count_o <= cycle_count_o + 32'd1;
        end
    end

    // FSM State Register (always_ff)
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state_q <= ST_IDLE;
        end else begin
            state_q <= state_d;
        end
    end

    // FSM Next State and Datapath Control (always_comb)
    always_comb begin
        state_d = state_q;
        busy_o  = 1'b1;
        done_o  = 1'b0;

        case (state_q)
            ST_IDLE: begin
                busy_o = 1'b0;
                if (start_i) begin
                    state_d = ST_L1_LOAD_BIAS;
                end
            end

            ST_L1_LOAD_BIAS: begin
                state_d = ST_L1_STREAM;
            end

            ST_L1_STREAM: begin
                if (l1_k_q == (L1_INPUT_DIM - 1)) begin
                    state_d = ST_L1_DRAIN;
                end
            end

            ST_L1_DRAIN: begin
                state_d = ST_L1_WRITEBACK;
            end

            ST_L1_WRITEBACK: begin
                if (l1_grp_q == 4'd15) begin
                    state_d = ST_L2_LOAD_BIAS;
                end else begin
                    state_d = ST_L1_LOAD_BIAS;
                end
            end

            ST_L2_LOAD_BIAS: begin
                state_d = ST_L2_STREAM;
            end

            ST_L2_STREAM: begin
                if (l2_k_q == 6'd63) begin
                    state_d = ST_L2_DRAIN;
                end
            end

            ST_L2_DRAIN: begin
                if (l2_drain_step_q != 2'd2) begin
                    state_d = ST_L2_DRAIN;
                end else if (l2_grp_q == 2'd2) begin
                    state_d = ST_DONE;
                end else begin
                    state_d = ST_L2_LOAD_BIAS;
                end
            end

            ST_DONE: begin
                busy_o = 1'b0;
                done_o = 1'b1;
                if (!start_i) begin
                    state_d = ST_IDLE;
                end
            end

            default: state_d = ST_IDLE;
        endcase
    end

    // Address Generators and Control Signals (always_ff)
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            l1_grp_q          <= 4'd0;
            l1_k_q            <= 10'd0;
            l2_grp_q          <= 2'd0;
            l2_k_q            <= 6'd0;
            l2_drain_step_q   <= 2'd0;
            w_addr_o          <= 14'd0;
            l1_in_addr_o      <= 10'd0;
            l2_in_addr_o      <= 6'd0;
            l1_bias_grp_o     <= 4'd0;
            l2_bias_grp_o     <= 2'd0;
            l1_wb_we_o        <= 1'b0;
            l1_wb_addr_o      <= 6'd0;
            pe_clr_o          <= 1'b0;
            pe_valid_o        <= 1'b0;
            pe_sel_l2_o       <= 1'b0;
            stream_valid_pipe <= 1'b0;
        end else begin
            pe_clr_o          <= 1'b0;
            pe_valid_o        <= stream_valid_pipe;
            l1_wb_we_o        <= 1'b0;

            case (state_q)
                ST_IDLE: begin
                    l1_grp_q          <= 4'd0;
                    l2_grp_q          <= 2'd0;
                    l2_drain_step_q   <= 2'd0;
                    stream_valid_pipe <= 1'b0;
                end

                ST_L1_LOAD_BIAS: begin
                    pe_clr_o          <= 1'b1;
                    pe_sel_l2_o       <= 1'b0;
                    l1_bias_grp_o     <= l1_grp_q;
                    l1_k_q            <= 10'd0;
                    w_addr_o          <= 14'(l1_grp_q * 14'd784);
                    l1_in_addr_o      <= 10'd0;
                    stream_valid_pipe <= 1'b1;
                end

                ST_L1_STREAM: begin
                    pe_sel_l2_o <= 1'b0;
                    if (l1_k_q == (L1_INPUT_DIM - 1)) begin
                        stream_valid_pipe <= 1'b0;
                    end else begin
                        stream_valid_pipe <= 1'b1;
                        l1_k_q       <= l1_k_q + 10'd1;
                        l1_in_addr_o <= l1_k_q + 10'd1;
                        w_addr_o     <= 14'(l1_grp_q * 14'd784) + 14'(l1_k_q + 10'd1);
                    end
                end

                ST_L1_DRAIN: begin
                    stream_valid_pipe <= 1'b0;
                end

                ST_L1_WRITEBACK: begin
                    l1_wb_we_o   <= 1'b1;
                    l1_wb_addr_o <= {l1_grp_q, 2'b00};
                    l1_grp_q     <= l1_grp_q + 4'd1;
                end

                ST_L2_LOAD_BIAS: begin
                    pe_clr_o          <= 1'b1;
                    pe_sel_l2_o       <= 1'b1;
                    l2_bias_grp_o     <= l2_grp_q;
                    l2_k_q            <= 6'd0;
                    w_addr_o          <= 14'd12544 + 14'(l2_grp_q * 14'd64);
                    l2_in_addr_o      <= 6'd0;
                    stream_valid_pipe <= 1'b1;
                end

                ST_L2_STREAM: begin
                    pe_sel_l2_o <= 1'b1;
                    if (l2_k_q == 6'd63) begin
                        stream_valid_pipe <= 1'b0;
                    end else begin
                        stream_valid_pipe <= 1'b1;
                        l2_k_q       <= l2_k_q + 6'd1;
                        l2_in_addr_o <= l2_k_q + 6'd1;
                        w_addr_o     <= 14'd12544 + 14'(l2_grp_q * 14'd64) + 14'(l2_k_q + 6'd1);
                    end
                end

                ST_L2_DRAIN: begin
                    stream_valid_pipe <= 1'b0;
                    if (l2_drain_step_q < 2'd2) begin
                        l2_drain_step_q <= l2_drain_step_q + 2'd1;
                    end else begin
                        l2_drain_step_q <= 2'd0;
                        l2_grp_q        <= l2_grp_q + 2'd1;
                    end
                end

                ST_DONE: begin
                    stream_valid_pipe <= 1'b0;
                end
            endcase
        end
    end

endmodule : hwpe_stream_ctrl
