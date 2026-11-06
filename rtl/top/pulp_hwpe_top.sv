// ============================================================================
// File: pulp_hwpe_top.sv
// Project: PULP-inspired Edge AI SoC for Handwritten Digit Recognition
// Module: pulp_hwpe_top (SystemVerilog Top-level Hardware Processing Engine)
// Author: Nguyen Van Thuc (24161421)
// Description:
//   Complete autonomous Edge AI Accelerator implementing the PULP-inspired
//   decoupled HWPE + TCDM architecture for real-time handwritten digit recognition.
//   SystemVerilog implementation using IEEE 1800-2012 syntax.
// ============================================================================

`timescale 1ns / 1ps

import pulp_hwpe_pkg::*;

module pulp_hwpe_top #(
    parameter int unsigned SHIFT_BITS = pulp_hwpe_pkg::SHIFT_BITS,
    parameter WEIGHTS_FILE     = "/workspace/projects/pulp_edge_ai_soc/sw/data/weights_tcdm.hex",
    parameter BIAS_L1_FILE     = "/workspace/projects/pulp_edge_ai_soc/sw/data/biases_l1.hex",
    parameter BIAS_L2_FILE     = "/workspace/projects/pulp_edge_ai_soc/sw/data/biases_l2.hex",
    parameter INIT_IMAGE_FILE  = ""
)(
    input  logic                 clk,
    input  logic                 rst_n,

    // Host Control / Status Interface
    input  logic                 start_i,
    output logic                 busy_o,
    output logic                 done_o,
    output logic [3:0]           pred_class_o,
    output logic signed [31:0]   best_logit_o,
    output logic [31:0]          cycle_count_o,

    // Host Direct Activation / Image Loading Interface
    input  logic                 host_we_i,
    input  logic [9:0]           host_addr_i,
    input  logic [7:0]           host_wdata_i
);

    // ------------------------------------------------------------------------
    // Internal Interconnect Signals
    // ------------------------------------------------------------------------
    // Stream Controller <-> TCDM Weight Memory
    logic [13:0] w_addr;
    logic [47:0] w_rdata;

    // Stream Controller <-> TCDM Activation Memory
    logic [9:0]  l1_in_addr;
    logic [7:0]  l1_in_data;
    logic        l1_wb_we;
    logic [5:0]  l1_wb_addr;
    logic [5:0]  l2_in_addr;
    logic [7:0]  l2_in_data;

    // Stream Controller <-> TCDM Bias Memory
    logic [3:0]   l1_bias_grp;
    logic [1:0]   l2_bias_grp;
    logic [127:0] l1_biases;
    logic [127:0] l2_biases;

    // Stream Controller <-> Compute Engine
    logic         pe_clr;
    logic         pe_valid;
    logic         pe_sel_l2;
    logic [127:0] pe_acc_out;

    // Stream Controller <-> Argmax Unit
    logic         argmax_clr;
    logic         argmax_update;
    logic [1:0]   argmax_grp;

    // ------------------------------------------------------------------------
    // Datapath Multiplexing
    // ------------------------------------------------------------------------
    // Activation fed to 1x4 PE array (broadcasted)
    logic signed [7:0]   cur_act;
    assign cur_act = pe_sel_l2 ? signed'(l2_in_data) : signed'(l1_in_data);

    // Bias fed to 1x4 PE array (128-bit = 4 x 32-bit)
    logic signed [127:0] cur_biases;
    assign cur_biases = pe_sel_l2 ? l2_biases : l1_biases;

    // Requantized Layer 1 writeback activations
    logic [31:0] l1_wb_packed_data;

    genvar g;
    generate
        for (g = 0; g < 4; g = g + 1) begin : gen_requant
            logic signed [7:0] act_byte;
            requant_relu #(
                .SHIFT_BITS(SHIFT_BITS)
            ) u_requant (
                .data_i(pe_acc_out[32*g +: 32]),
                .data_o(act_byte)
            );
            assign l1_wb_packed_data[8*g +: 8] = act_byte;
        end
    endgenerate

    // ------------------------------------------------------------------------
    // Submodule Instantiations
    // ------------------------------------------------------------------------

    // 1. HWPE Stream Controller & AGU
    hwpe_stream_ctrl #(
        .L1_INPUT_DIM(pulp_hwpe_pkg::L1_INPUT_DIM),
        .L1_NEURONS(pulp_hwpe_pkg::L1_NEURONS),
        .L2_NEURONS(pulp_hwpe_pkg::L2_NEURONS),
        .SHIFT_BITS(SHIFT_BITS)
    ) u_stream_ctrl (
        .clk(clk),
        .rst_n(rst_n),
        .start_i(start_i),
        .busy_o(busy_o),
        .done_o(done_o),
        .cycle_count_o(cycle_count_o),
        .w_addr_o(w_addr),
        .l1_in_addr_o(l1_in_addr),
        .l1_wb_we_o(l1_wb_we),
        .l1_wb_addr_o(l1_wb_addr),
        .l2_in_addr_o(l2_in_addr),
        .l1_bias_grp_o(l1_bias_grp),
        .l2_bias_grp_o(l2_bias_grp),
        .pe_clr_o(pe_clr),
        .pe_valid_o(pe_valid),
        .pe_sel_l2_o(pe_sel_l2),
        .argmax_clr_o(argmax_clr),
        .argmax_update_o(argmax_update),
        .argmax_grp_o(argmax_grp)
    );

    // 2. TCDM Weight Memory (51 KB BRAM)
    tcdm_weight_bram #(
        .DEPTH(pulp_hwpe_pkg::WEIGHT_MEM_DEPTH),
        .ADDR_W(14),
        .INIT_FILE(WEIGHTS_FILE)
    ) u_weight_mem (
        .clk(clk),
        .we_i(1'b0),
        .addr_i(w_addr),
        .wdata_i(48'd0),
        .rdata_o(w_rdata)
    );

    // 3. TCDM Activation Memory (Input Image 784B + Hidden Layer 64B)
    tcdm_activation_mem #(
        .INIT_IMAGE_FILE(INIT_IMAGE_FILE)
    ) u_act_mem (
        .clk(clk),
        .rst_n(rst_n),
        .host_we_i(host_we_i),
        .host_addr_i(host_addr_i),
        .host_wdata_i(host_wdata_i),
        .l1_raddr_i(l1_in_addr),
        .l1_rdata_o(l1_in_data),
        .l1_wb_we_i(l1_wb_we),
        .l1_wb_addr_i(l1_wb_addr),
        .l1_wb_data_i(l1_wb_packed_data),
        .l2_raddr_i(l2_in_addr),
        .l2_rdata_o(l2_in_data)
    );

    // 4. TCDM Bias Storage
    tcdm_bias_mem #(
        .BIAS_L1_FILE(BIAS_L1_FILE),
        .BIAS_L2_FILE(BIAS_L2_FILE)
    ) u_bias_mem (
        .clk(clk),
        .l1_grp_i(l1_bias_grp),
        .l1_biases_o(l1_biases),
        .l2_grp_i(l2_bias_grp),
        .l2_biases_o(l2_biases)
    );

    // 5. 1x4 SIMD Approximate Compute Engine (Zero-DSP lutalm_mul_s8)
    compute_engine_1x4 #(
        .LOW_W(3),
        .TRUNC_BITS(4),
        .ROUND_MODE(1),
        .ADAPTIVE_LUT(0),
        .USE_CARRY(1),
        .QUAD_CURV(0)
    ) u_compute_engine (
        .clk(clk),
        .rst_n(rst_n),
        .valid_i(pe_valid),
        .clr_i(pe_clr),
        .act_i(cur_act),
        .weights_i(w_rdata),
        .biases_i(cur_biases),
        .acc_o(pe_acc_out)
    );

    // 6. Argmax Unit (Classifier Output 0..9)
    argmax_unit u_argmax (
        .clk(clk),
        .rst_n(rst_n),
        .clr_i(argmax_clr),
        .update_i(argmax_update),
        .grp_i(argmax_grp),
        .logit0_i(pe_acc_out[31:0]),
        .logit1_i(pe_acc_out[63:32]),
        .logit2_i(pe_acc_out[95:64]),
        .logit3_i(pe_acc_out[127:96]),
        .best_class_o(pred_class_o),
        .best_logit_o(best_logit_o)
    );

endmodule : pulp_hwpe_top
