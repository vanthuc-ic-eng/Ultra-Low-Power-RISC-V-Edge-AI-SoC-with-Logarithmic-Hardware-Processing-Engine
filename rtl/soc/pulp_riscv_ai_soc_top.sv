// ============================================================================
// File: pulp_riscv_ai_soc_top.sv
// Project: PULP-inspired Edge AI SoC for Handwritten Digit Recognition
// Module: pulp_riscv_ai_soc_top (Complete Edge AI System-on-Chip Top-Level)
// Author: Nguyen Van Thuc (24161421)
// Description:
//   Complete autonomous System-on-Chip integrating:
//   1. Lightweight 32-bit RISC-V RV32I Processor (Control Plane Host).
//   2. Crossbar Interconnect with Memory-Mapped I/O.
//   3. 4 KB Boot ROM & 4 KB Data SRAM.
//   4. UART Debug Transmitter.
//   5. Autonomous HWPE AI Accelerator Subsystem (Data Plane) featuring:
//      - Multi-banked TCDM on-chip memory (51 KB).
//      - 1x4 Output-Stationary SIMD Engine with Zero-DSP lutalm_mul_s8 (v0.3.0).
//      - Autonomous Stream Controller & Fused Requant-ReLU / Argmax Classifier.
//   SystemVerilog IEEE 1800-2012 implementation.
// ============================================================================

`timescale 1ns / 1ps

import pulp_hwpe_pkg::*;

module pulp_riscv_ai_soc_top #(
    parameter BOOT_HEX_FILE  = "/workspace/projects/pulp_edge_ai_soc/sw/firmware/boot_rom.hex",
    parameter WEIGHTS_FILE   = "/workspace/projects/pulp_edge_ai_soc/sw/data/weights_tcdm.hex",
    parameter BIAS_L1_FILE   = "/workspace/projects/pulp_edge_ai_soc/sw/data/biases_l1.hex",
    parameter BIAS_L2_FILE   = "/workspace/projects/pulp_edge_ai_soc/sw/data/biases_l2.hex",
    parameter CLK_FREQ_HZ    = 100_000_000,
    parameter BAUD_RATE      = 115_200
)(
    input  logic        clk,
    input  logic        rst_n,

    // UART Serial Port Output (To PC Terminal)
    output logic        uart_txd_o,

    // On-Board Status LEDs
    output logic        led_busy_o,
    output logic        led_done_o,
    output logic [3:0]  led_pred_o
);

    // ------------------------------------------------------------------------
    // Internal Interconnect Nets
    // ------------------------------------------------------------------------
    // CPU Instruction Fetch Port
    logic [31:0] cpu_iaddr;
    logic        cpu_ireq;
    logic [31:0] cpu_idata;
    logic        cpu_ivalid;

    // CPU Data Load/Store Port
    logic [31:0] cpu_daddr;
    logic [31:0] cpu_dwdata;
    logic [3:0]  cpu_dbe;
    logic        cpu_dwe;
    logic        cpu_dreq;
    logic [31:0] cpu_drdata;
    logic        cpu_dvalid;

    // Interrupt Line
    logic        hwpe_irq;

    // Slave 0: Boot ROM Data Port
    logic [11:0] rom_daddr;
    logic        rom_dreq;
    logic [31:0] rom_drdata;
    logic        rom_dvalid;

    // Slave 1: Data RAM Port
    logic [11:0] ram_addr;
    logic [31:0] ram_wdata;
    logic [3:0]  ram_be;
    logic        ram_we;
    logic        ram_req;
    logic [31:0] ram_rdata;
    logic        ram_valid;

    // Slave 2: HWPE Accelerator Port
    logic [12:0] hwpe_addr;
    logic [31:0] hwpe_wdata;
    logic [3:0]  hwpe_be;
    logic        hwpe_we;
    logic        hwpe_req;
    logic [31:0] hwpe_rdata;
    logic        hwpe_valid;

    // Slave 3: UART Port
    logic [3:0]  uart_addr;
    logic [31:0] uart_wdata;
    logic        uart_we;
    logic        uart_req;
    logic [31:0] uart_rdata;
    logic        uart_valid;

    // ------------------------------------------------------------------------
    // 1. Lightweight RISC-V RV32I Processor Core (Control Plane Host)
    // ------------------------------------------------------------------------
    riscv_core_rv32i #(
        .BOOT_ADDR(32'h0000_0000)
    ) u_cpu (
        .clk(clk),
        .rst_n(rst_n),
        .instr_addr_o(cpu_iaddr),
        .instr_req_o(cpu_ireq),
        .instr_data_i(cpu_idata),
        .instr_valid_i(cpu_ivalid),
        .data_addr_o(cpu_daddr),
        .data_wdata_o(cpu_dwdata),
        .data_be_o(cpu_dbe),
        .data_we_o(cpu_dwe),
        .data_req_o(cpu_dreq),
        .data_rdata_i(cpu_drdata),
        .data_valid_i(cpu_dvalid),
        .irq_i(hwpe_irq),
        .irq_ack_o()
    );

    // ------------------------------------------------------------------------
    // 2. Boot ROM (4 KB - Dual Port for Instruction Fetch + Data Load)
    // ------------------------------------------------------------------------
    (* ram_style = "block" *) logic [31:0] rom_mem [0:1023];

    initial begin
        if (BOOT_HEX_FILE != "") begin
            $readmemh(BOOT_HEX_FILE, rom_mem);
        end
    end

    // Instruction & Data Ports (Pure synchronous BRAM read, no async reset)
    always_ff @(posedge clk) begin
        cpu_idata  <= rom_mem[cpu_iaddr[11:2]];
        rom_drdata <= rom_mem[rom_daddr[11:2]];
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            cpu_ivalid <= 1'b0;
            rom_dvalid <= 1'b0;
        end else begin
            cpu_ivalid <= cpu_ireq;
            rom_dvalid <= rom_dreq;
        end
    end

    // ------------------------------------------------------------------------
    // 3. Data SRAM (4 KB - Single Cycle BRAM Access)
    // ------------------------------------------------------------------------
    (* ram_style = "block" *) logic [31:0] ram_mem [0:1023];

    always_ff @(posedge clk) begin
        if (ram_req && ram_we) begin
            if (ram_be[0]) ram_mem[ram_addr[11:2]][7:0]   <= ram_wdata[7:0];
            if (ram_be[1]) ram_mem[ram_addr[11:2]][15:8]  <= ram_wdata[15:8];
            if (ram_be[2]) ram_mem[ram_addr[11:2]][23:16] <= ram_wdata[23:16];
            if (ram_be[3]) ram_mem[ram_addr[11:2]][31:24] <= ram_wdata[31:24];
        end
        ram_rdata <= ram_mem[ram_addr[11:2]];
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            ram_valid <= 1'b0;
        end else begin
            ram_valid <= ram_req;
        end
    end

    // ------------------------------------------------------------------------
    // 4. Crossbar Interconnect (Control Plane Routing)
    // ------------------------------------------------------------------------
    soc_bus_interconnect u_interconnect (
        .clk(clk),
        .rst_n(rst_n),
        .cpu_daddr_i(cpu_daddr),
        .cpu_dwdata_i(cpu_dwdata),
        .cpu_dbe_i(cpu_dbe),
        .cpu_dwe_i(cpu_dwe),
        .cpu_dreq_i(cpu_dreq),
        .cpu_drdata_o(cpu_drdata),
        .cpu_dvalid_o(cpu_dvalid),

        .rom_addr_o(rom_daddr),
        .rom_req_o(rom_dreq),
        .rom_rdata_i(rom_drdata),
        .rom_valid_i(rom_dvalid),

        .ram_addr_o(ram_addr),
        .ram_wdata_o(ram_wdata),
        .ram_be_o(ram_be),
        .ram_we_o(ram_we),
        .ram_req_o(ram_req),
        .ram_rdata_i(ram_rdata),
        .ram_valid_i(ram_valid),

        .hwpe_addr_o(hwpe_addr),
        .hwpe_wdata_o(hwpe_wdata),
        .hwpe_be_o(hwpe_be),
        .hwpe_we_o(hwpe_we),
        .hwpe_req_o(hwpe_req),
        .hwpe_rdata_i(hwpe_rdata),
        .hwpe_valid_i(hwpe_valid),

        .uart_addr_o(uart_addr),
        .uart_wdata_o(uart_wdata),
        .uart_we_o(uart_we),
        .uart_req_o(uart_req),
        .uart_rdata_i(uart_rdata),
        .uart_valid_i(uart_valid)
    );

    // ------------------------------------------------------------------------
    // 5. UART Debug Transmitter Peripheral
    // ------------------------------------------------------------------------
    uart_tx #(
        .CLK_FREQ_HZ(CLK_FREQ_HZ),
        .BAUD_RATE(BAUD_RATE)
    ) u_uart (
        .clk(clk),
        .rst_n(rst_n),
        .req_i(uart_req),
        .we_i(uart_we),
        .addr_i(uart_addr),
        .wdata_i(uart_wdata),
        .rdata_o(uart_rdata),
        .valid_o(uart_valid),
        .uart_txd_o(uart_txd_o)
    );

    // ------------------------------------------------------------------------
    // 6. Autonomous HWPE AI Accelerator Subsystem (Data Plane)
    // ------------------------------------------------------------------------
    hwpe_csr_wrapper #(
        .WEIGHTS_FILE(WEIGHTS_FILE),
        .BIAS_L1_FILE(BIAS_L1_FILE),
        .BIAS_L2_FILE(BIAS_L2_FILE)
    ) u_hwpe_subsystem (
        .clk(clk),
        .rst_n(rst_n),
        .req_i(hwpe_req),
        .we_i(hwpe_we),
        .addr_i(hwpe_addr),
        .wdata_i(hwpe_wdata),
        .be_i(hwpe_be),
        .rdata_o(hwpe_rdata),
        .valid_o(hwpe_valid),
        .irq_o(hwpe_irq)
    );

    // Status LED assignments
    assign led_busy_o = u_hwpe_subsystem.hwpe_busy;
    assign led_done_o = u_hwpe_subsystem.done_latched_q;
    assign led_pred_o = u_hwpe_subsystem.pred_class_latched_q;

endmodule : pulp_riscv_ai_soc_top
