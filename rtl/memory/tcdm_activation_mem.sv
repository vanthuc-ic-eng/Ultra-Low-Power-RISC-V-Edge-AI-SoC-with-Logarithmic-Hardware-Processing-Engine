// ============================================================================
// File: tcdm_activation_mem.sv
// Project: PULP-inspired Edge AI SoC for Handwritten Digit Recognition
// Module: tcdm_activation_mem (SystemVerilog TCDM Activation Memory)
// Author: Nguyen Van Thuc (24161421)
// Description:
//   Tightly-Coupled Data Memory (TCDM) for Activations.
//   - Bank 0 (Input Image): 1024 bytes (Stores 784 input pixels).
//   - Bank 1 (Hidden Layer): 64 bytes (Stores 64 hidden activations).
//   SystemVerilog implementation using IEEE 1800-2012 syntax.
// ============================================================================

`timescale 1ns / 1ps

module tcdm_activation_mem #(
    parameter INIT_IMAGE_FILE = ""
)(
    input  logic        clk,
    input  logic        rst_n,

    // Host / Input loading interface
    input  logic        host_we_i,
    input  logic [9:0]  host_addr_i,
    input  logic [7:0]  host_wdata_i,

    // Layer 1 input read interface (Bank 0)
    input  logic [9:0]  l1_raddr_i,
    output logic [7:0]  l1_rdata_o,

    // Layer 1 writeback interface (Bank 1: writes 4 bytes into hidden bank)
    input  logic        l1_wb_we_i,
    input  logic [5:0]  l1_wb_addr_i, // Base address for 4 neurons (e.g. 0, 4, 8, ...)
    input  logic [31:0] l1_wb_data_i, // {act3, act2, act1, act0}

    // Layer 2 input read interface (Bank 1)
    input  logic [5:0]  l2_raddr_i,
    output logic [7:0]  l2_rdata_o
);

    // Bank 0: Input Image (1024 x 8-bit)
    (* ram_style = "distributed" *) logic [7:0] bank0_in [0:1023];

    // Bank 1: Hidden Layer (64 x 8-bit)
    (* ram_style = "distributed" *) logic [7:0] bank1_hidden [0:63];

    initial begin
        for (int idx = 0; idx < 1024; idx++) bank0_in[idx] = 8'h00;
        for (int idx = 0; idx < 64; idx++)   bank1_hidden[idx] = 8'h00;
        if (INIT_IMAGE_FILE != "") begin
            $readmemh(INIT_IMAGE_FILE, bank0_in);
        end
    end

    // Bank 0 write / read
    always_ff @(posedge clk) begin
        if (host_we_i) begin
            bank0_in[host_addr_i] <= host_wdata_i;
        end
        l1_rdata_o <= bank0_in[l1_raddr_i];
    end

    // Bank 1 write (from Layer 1 writeback) and read (to Layer 2)
    always_ff @(posedge clk) begin
        if (l1_wb_we_i) begin
            bank1_hidden[l1_wb_addr_i + 0] <= l1_wb_data_i[7:0];
            bank1_hidden[l1_wb_addr_i + 1] <= l1_wb_data_i[15:8];
            bank1_hidden[l1_wb_addr_i + 2] <= l1_wb_data_i[23:16];
            bank1_hidden[l1_wb_addr_i + 3] <= l1_wb_data_i[31:24];
        end
        l2_rdata_o <= bank1_hidden[l2_raddr_i];
    end

endmodule : tcdm_activation_mem
