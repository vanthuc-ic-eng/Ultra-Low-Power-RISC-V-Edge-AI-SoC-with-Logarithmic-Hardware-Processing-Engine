// ============================================================================
// File: tcdm_weight_bram.sv
// Project: PULP-inspired Edge AI SoC for Handwritten Digit Recognition
// Module: tcdm_weight_bram (SystemVerilog TCDM Weight Memory)
// Author: Nguyen Van Thuc (24161421)
// Description:
//   Tightly-Coupled Data Memory (TCDM) for Network Weights.
//   Depth: 16384 words x 32-bit (64 KB capacity, fits L1 12,544 + L2 192 words).
//   SystemVerilog implementation using IEEE 1800-2012 syntax.
// ============================================================================

`timescale 1ns / 1ps

module tcdm_weight_bram #(
    parameter int unsigned DEPTH  = 16384,
    parameter int unsigned ADDR_W = 14,
    parameter              INIT_FILE = ""
)(
    input  logic              clk,
    input  logic              we_i,
    input  logic [ADDR_W-1:0] addr_i,
    input  logic [31:0]       wdata_i,
    output logic [31:0]       rdata_o
);

    (* ram_style = "block" *) logic [31:0] mem [0:DEPTH-1];

    initial begin
        if (INIT_FILE != "") begin
            $readmemh(INIT_FILE, mem);
        end
    end

    always_ff @(posedge clk) begin
        if (we_i) begin
            mem[addr_i] <= wdata_i;
        end
        rdata_o <= mem[addr_i];
    end

endmodule : tcdm_weight_bram
