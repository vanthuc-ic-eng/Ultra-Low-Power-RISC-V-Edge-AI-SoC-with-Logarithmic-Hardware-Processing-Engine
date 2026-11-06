// ============================================================================
// File: hwpe_csr_wrapper.sv
// Project: PULP-inspired Edge AI SoC for Handwritten Digit Recognition
// Module: hwpe_csr_wrapper (Memory-Mapped CSR & DMA Wrapper for HWPE Accelerator)
// Author: Nguyen Van Thuc (24161421)
// Description:
//   Memory-mapped adapter wrapping pulp_hwpe_top.sv for seamless integration
//   into the RISC-V SoC Control Plane.
//   - Offset 0x00: REG_CTRL (Bit 0: START, Bit 1: IRQ_CLR)
//   - Offset 0x04: REG_STATUS (Bit 0: BUSY, Bit 1: DONE, Bit 2: IRQ_PENDING)
//   - Offset 0x08: REG_PRED_CLASS (Bits 3:0: Predicted digit 0..9)
//   - Offset 0x0C: REG_BEST_LOGIT (Signed 32-bit score)
//   - Offset 0x10: REG_CYCLE_COUNT (Hardware execution cycle count)
//   - Offset 0x1000..0x13FF: TCDM Activation Buffer (784-byte direct write)
//   SystemVerilog IEEE 1800-2012 implementation.
// ============================================================================

`timescale 1ns / 1ps

import pulp_hwpe_pkg::*;

module hwpe_csr_wrapper #(
    parameter WEIGHTS_FILE = "/workspace/projects/pulp_edge_ai_soc/sw/data/weights_tcdm.hex",
    parameter BIAS_L1_FILE = "/workspace/projects/pulp_edge_ai_soc/sw/data/biases_l1.hex",
    parameter BIAS_L2_FILE = "/workspace/projects/pulp_edge_ai_soc/sw/data/biases_l2.hex"
)(
    input  logic        clk,
    input  logic        rst_n,

    // Bus Slave Interface (Control Plane)
    input  logic        req_i,
    input  logic        we_i,
    input  logic [12:0] addr_i,     // 8 KB address space (0x0000 - 0x1FFF)
    input  logic [31:0] wdata_i,
    input  logic [3:0]  be_i,
    output logic [31:0] rdata_o,
    output logic        valid_o,

    // Hardware Interrupt Output
    output logic        irq_o
);

    // ------------------------------------------------------------------------
    // HWPE Instance Interface Signals
    // ------------------------------------------------------------------------
    logic        hwpe_start;
    logic        hwpe_busy;
    logic        hwpe_done;
    logic [3:0]  hwpe_pred_class;
    logic signed [31:0] hwpe_best_logit;
    logic [31:0] hwpe_cycle_count;

    logic        host_we;
    logic [9:0]  host_addr;
    logic [7:0]  host_wdata;

    // Interrupt & Status Latches
    logic        irq_pending_q;
    logic        done_latched_q;
    logic [3:0]  pred_class_latched_q;
    logic signed [31:0] best_logit_latched_q;
    logic [31:0] cycle_count_latched_q;

    assign irq_o = irq_pending_q;

    // ------------------------------------------------------------------------
    // CSR & Image Write Address Decoding
    // ------------------------------------------------------------------------
    logic is_image_addr;
    logic is_csr_addr;

    assign is_image_addr = (addr_i[12]);       // 0x1000 - 0x1FFF
    assign is_csr_addr   = (!addr_i[12]);      // 0x0000 - 0x0FFF

    // Image Direct Write Logic (Byte / Word access)
    always_comb begin
        if (req_i && we_i && is_image_addr) begin
            host_we    = 1'b1;
            host_addr  = addr_i[9:0];
            // Format write byte from corresponding byte lane
            case (be_i)
                4'b0001: host_wdata = wdata_i[7:0];
                4'b0010: host_wdata = wdata_i[15:8];
                4'b0100: host_wdata = wdata_i[23:16];
                4'b1000: host_wdata = wdata_i[31:24];
                default: host_wdata = wdata_i[7:0];
            endcase
        end else begin
            host_we    = 1'b0;
            host_addr  = 10'd0;
            host_wdata = 8'd0;
        end
    end

    // CSR Read Synchronous Registration (1-cycle read latency)
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            valid_o <= 1'b0;
            rdata_o <= 32'd0;
        end else begin
            valid_o <= req_i;
            if (req_i && !we_i) begin
                if (is_csr_addr) begin
                    case (addr_i[5:2])
                        4'h0: rdata_o <= {31'd0, hwpe_start};
                        4'h1: rdata_o <= {29'd0, irq_pending_q, done_latched_q, hwpe_busy};
                        4'h2: rdata_o <= {28'd0, pred_class_latched_q};
                        4'h3: rdata_o <= best_logit_latched_q;
                        4'h4: rdata_o <= cycle_count_latched_q;
                        default: rdata_o <= 32'd0;
                    endcase
                end else begin
                    rdata_o <= 32'd0;
                end
            end else begin
                rdata_o <= 32'd0;
            end
        end
    end

    // CSR Writes & Pulse Generation
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            hwpe_start           <= 1'b0;
            irq_pending_q        <= 1'b0;
            done_latched_q       <= 1'b0;
            pred_class_latched_q <= 4'd0;
            best_logit_latched_q <= 32'd0;
            cycle_count_latched_q<= 32'd0;
        end else begin
            // Default 1-cycle pulses
            hwpe_start <= 1'b0;

            // Handle HWPE completion
            if (hwpe_done) begin
                done_latched_q       <= 1'b1;
                irq_pending_q        <= 1'b1;
                pred_class_latched_q <= hwpe_pred_class;
                best_logit_latched_q <= hwpe_best_logit;
                cycle_count_latched_q<= hwpe_cycle_count;
            end

            // CPU CSR Writes
            if (req_i && we_i && is_csr_addr) begin
                case (addr_i[5:2])
                    4'h0: begin // REG_CTRL
                        if (wdata_i[0]) begin
                            hwpe_start     <= 1'b1; // Trigger inference
                            done_latched_q <= 1'b0;
                            irq_pending_q  <= 1'b0;
                        end
                        if (wdata_i[1]) begin
                            irq_pending_q  <= 1'b0; // Clear IRQ
                        end
                    end
                    default: ;
                endcase
            end
        end
    end

    // ------------------------------------------------------------------------
    // Instantiate Core HWPE Accelerator (Decoupled TCDM + Zero-DSP Engine)
    // ------------------------------------------------------------------------
    pulp_hwpe_top #(
        .WEIGHTS_FILE(WEIGHTS_FILE),
        .BIAS_L1_FILE(BIAS_L1_FILE),
        .BIAS_L2_FILE(BIAS_L2_FILE),
        .INIT_IMAGE_FILE("")
    ) u_hwpe (
        .clk(clk),
        .rst_n(rst_n),
        .start_i(hwpe_start),
        .busy_o(hwpe_busy),
        .done_o(hwpe_done),
        .pred_class_o(hwpe_pred_class),
        .best_logit_o(hwpe_best_logit),
        .cycle_count_o(hwpe_cycle_count),
        .host_we_i(host_we),
        .host_addr_i(host_addr),
        .host_wdata_i(host_wdata)
    );

endmodule : hwpe_csr_wrapper
