// ============================================================================
// File: soc_bus_interconnect.sv
// Project: PULP-inspired Edge AI SoC for Handwritten Digit Recognition
// Module: soc_bus_interconnect (Memory Map Decoder & Crossbar Interconnect)
// Author: Nguyen Van Thuc (24161421)
// Description:
//   Crossbar interconnect for the RISC-V SoC Control Plane.
//   Routes CPU Data requests to:
//   - 0x0000_0000..0x0000_0FFF: Boot ROM (4 KB)
//   - 0x2000_0000..0x2000_0FFF: Data SRAM (4 KB)
//   - 0x4000_0000..0x4000_1FFF: HWPE AI Accelerator CSRs & Image Buffer (8 KB)
//   - 0x5000_0000..0x5000_000F: UART Peripheral (16 B)
//   SystemVerilog IEEE 1800-2012 implementation.
// ============================================================================

`timescale 1ns / 1ps

module soc_bus_interconnect (
    input  logic        clk,
    input  logic        rst_n,

    // CPU Data Master Port
    input  logic [31:0] cpu_daddr_i,
    input  logic [31:0] cpu_dwdata_i,
    input  logic [3:0]  cpu_dbe_i,
    input  logic        cpu_dwe_i,
    input  logic        cpu_dreq_i,
    output logic [31:0] cpu_drdata_o,
    output logic        cpu_dvalid_o,

    // Slave 0: Boot ROM Data Read
    output logic [11:0] rom_addr_o,
    output logic        rom_req_o,
    input  logic [31:0] rom_rdata_i,
    input  logic        rom_valid_i,

    // Slave 1: Data RAM
    output logic [11:0] ram_addr_o,
    output logic [31:0] ram_wdata_o,
    output logic [3:0]  ram_be_o,
    output logic        ram_we_o,
    output logic        ram_req_o,
    input  logic [31:0] ram_rdata_i,
    input  logic        ram_valid_i,

    // Slave 2: HWPE Accelerator
    output logic [12:0] hwpe_addr_o,
    output logic [31:0] hwpe_wdata_o,
    output logic [3:0]  hwpe_be_o,
    output logic        hwpe_we_o,
    output logic        hwpe_req_o,
    input  logic [31:0] hwpe_rdata_i,
    input  logic        hwpe_valid_i,

    // Slave 3: UART Transmitter
    output logic [3:0]  uart_addr_o,
    output logic [31:0] uart_wdata_o,
    output logic        uart_we_o,
    output logic        uart_req_o,
    input  logic [31:0] uart_rdata_i,
    input  logic        uart_valid_i
);

    // Address Decoding (Based on upper nibble)
    typedef enum logic [1:0] {
        SEL_ROM  = 2'b00,
        SEL_RAM  = 2'b01,
        SEL_HWPE = 2'b10,
        SEL_UART = 2'b11
    } target_e;

    target_e target_sel;

    always_comb begin
        case (cpu_daddr_i[31:28])
            4'h0: target_sel = SEL_ROM;
            4'h2: target_sel = SEL_RAM;
            4'h4: target_sel = SEL_HWPE;
            4'h5: target_sel = SEL_UART;
            default: target_sel = SEL_ROM;
        endcase
    end

    // Forward Request Signals
    assign rom_addr_o   = cpu_daddr_i[11:0];
    assign rom_req_o    = cpu_dreq_i && (target_sel == SEL_ROM);

    assign ram_addr_o   = cpu_daddr_i[11:0];
    assign ram_wdata_o  = cpu_dwdata_i;
    assign ram_be_o     = cpu_dbe_i;
    assign ram_we_o     = cpu_dwe_i;
    assign ram_req_o    = cpu_dreq_i && (target_sel == SEL_RAM);

    assign hwpe_addr_o  = cpu_daddr_i[12:0];
    assign hwpe_wdata_o = cpu_dwdata_i;
    assign hwpe_be_o    = cpu_dbe_i;
    assign hwpe_we_o    = cpu_dwe_i;
    assign hwpe_req_o   = cpu_dreq_i && (target_sel == SEL_HWPE);

    assign uart_addr_o  = cpu_daddr_i[3:0];
    assign uart_wdata_o = cpu_dwdata_i;
    assign uart_we_o    = cpu_dwe_i;
    assign uart_req_o   = cpu_dreq_i && (target_sel == SEL_UART);

    // Response Multiplexer
    always_comb begin
        case (target_sel)
            SEL_ROM: begin
                cpu_drdata_o = rom_rdata_i;
                cpu_dvalid_o = rom_valid_i;
            end
            SEL_RAM: begin
                cpu_drdata_o = ram_rdata_i;
                cpu_dvalid_o = ram_valid_i;
            end
            SEL_HWPE: begin
                cpu_drdata_o = hwpe_rdata_i;
                cpu_dvalid_o = hwpe_valid_i;
            end
            SEL_UART: begin
                cpu_drdata_o = uart_rdata_i;
                cpu_dvalid_o = uart_valid_i;
            end
            default: begin
                cpu_drdata_o = 32'd0;
                cpu_dvalid_o = 1'b0;
            end
        endcase
    end

endmodule : soc_bus_interconnect
