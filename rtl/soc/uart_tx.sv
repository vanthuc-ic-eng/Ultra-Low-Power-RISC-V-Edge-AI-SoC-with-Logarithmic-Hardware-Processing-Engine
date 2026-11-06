// ============================================================================
// File: uart_tx.sv
// Project: PULP-inspired Edge AI SoC for Handwritten Digit Recognition
// Module: uart_tx (Lightweight Memory-Mapped UART Transmitter)
// Author: Nguyen Van Thuc (24161421)
// Description:
//   Simple Memory-Mapped UART Transmitter (8-N-1 format).
//   Provides real-time terminal debug output for the RISC-V SoC.
//   SystemVerilog IEEE 1800-2012 implementation.
// ============================================================================

`timescale 1ns / 1ps

module uart_tx #(
    parameter int unsigned CLK_FREQ_HZ = 100_000_000,
    parameter int unsigned BAUD_RATE   = 115_200
)(
    input  logic        clk,
    input  logic        rst_n,

    // Bus Slave Interface
    input  logic        req_i,
    input  logic        we_i,
    input  logic [3:0]  addr_i,      // Word offset
    input  logic [31:0] wdata_i,
    output logic [31:0] rdata_o,
    output logic        valid_o,

    // Physical Serial Output
    output logic        uart_txd_o
);

    localparam int unsigned CLKS_PER_BIT = CLK_FREQ_HZ / BAUD_RATE;

    typedef enum logic [1:0] {
        TX_IDLE  = 2'b00,
        TX_START = 2'b01,
        TX_DATA  = 2'b10,
        TX_STOP  = 2'b11
    } tx_state_e;

    tx_state_e tx_state;
    logic [15:0] clk_count;
    logic [2:0]  bit_index;
    logic [7:0]  tx_data_reg;
    logic        tx_busy;

    assign tx_busy = (tx_state != TX_IDLE);

    // Bus Read
    always_comb begin
        if (req_i && !we_i) begin
            case (addr_i[3:2])
                2'b00: rdata_o = {24'd0, tx_data_reg};
                2'b01: rdata_o = {31'd0, !tx_busy}; // Bit 0: Ready
                default: rdata_o = 32'd0;
            endcase
            valid_o = 1'b1;
        end else begin
            rdata_o = 32'd0;
            valid_o = req_i && we_i;
        end
    end

    // UART Transmitter FSM
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            tx_state    <= TX_IDLE;
            clk_count   <= 16'd0;
            bit_index   <= 3'd0;
            tx_data_reg <= 8'd0;
            uart_txd_o  <= 1'b1; // Idle line is HIGH
        end else begin
            case (tx_state)
                TX_IDLE: begin
                    uart_txd_o <= 1'b1;
                    clk_count  <= 16'd0;
                    bit_index  <= 3'd0;
                    if (req_i && we_i && (addr_i[3:2] == 2'b00)) begin
                        tx_data_reg <= wdata_i[7:0];
                        tx_state    <= TX_START;
                    end
                end

                TX_START: begin
                    uart_txd_o <= 1'b0; // Start bit is LOW
                    if (clk_count < CLKS_PER_BIT - 1) begin
                        clk_count <= clk_count + 1'b1;
                    end else begin
                        clk_count <= 16'd0;
                        tx_state  <= TX_DATA;
                    end
                end

                TX_DATA: begin
                    uart_txd_o <= tx_data_reg[bit_index];
                    if (clk_count < CLKS_PER_BIT - 1) begin
                        clk_count <= clk_count + 1'b1;
                    end else begin
                        clk_count <= 16'd0;
                        if (bit_index < 3'd7) begin
                            bit_index <= bit_index + 1'b1;
                        end else begin
                            bit_index <= 3'd0;
                            tx_state  <= TX_STOP;
                        end
                    end
                end

                TX_STOP: begin
                    uart_txd_o <= 1'b1; // Stop bit is HIGH
                    if (clk_count < CLKS_PER_BIT - 1) begin
                        clk_count <= clk_count + 1'b1;
                    end else begin
                        clk_count <= 16'd0;
                        tx_state  <= TX_IDLE;
                    end
                end

                default: tx_state <= TX_IDLE;
            endcase
        end
    end

endmodule : uart_tx
