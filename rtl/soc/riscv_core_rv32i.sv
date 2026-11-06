// ============================================================================
// File: riscv_core_rv32i.sv
// Project: PULP-inspired Edge AI SoC for Handwritten Digit Recognition
// Module: riscv_core_rv32i (Lightweight 32-bit RISC-V RV32I Microcontroller Core)
// Author: Nguyen Van Thuc (24161421)
// Description:
//   Ultra-lightweight, area-efficient RV32I microcontroller core designed to act
//   as the Host Control Plane for the autonomous HWPE Edge AI Accelerator.
//   Implements Harvard instruction & data interfaces with minimal FPGA LUT overhead.
//   SystemVerilog IEEE 1800-2012 implementation.
// ============================================================================

`timescale 1ns / 1ps

module riscv_core_rv32i #(
    parameter logic [31:0] BOOT_ADDR = 32'h0000_0000
)(
    input  logic        clk,
    input  logic        rst_n,

    // Instruction Memory Interface (Fetch Port)
    output logic [31:0] instr_addr_o,
    output logic        instr_req_o,
    input  logic [31:0] instr_data_i,
    input  logic        instr_valid_i,

    // Data Memory Interface (Load/Store Port)
    output logic [31:0] data_addr_o,
    output logic [31:0] data_wdata_o,
    output logic [3:0]  data_be_o,
    output logic        data_we_o,
    output logic        data_req_o,
    input  logic [31:0] data_rdata_i,
    input  logic        data_valid_i,

    // Hardware Interrupt Interface
    input  logic        irq_i,
    output logic        irq_ack_o
);

    // ------------------------------------------------------------------------
    // FSM Execution States
    // ------------------------------------------------------------------------
    typedef enum logic [2:0] {
        STATE_FETCH    = 3'b000,
        STATE_DECODE   = 3'b001,
        STATE_EXECUTE  = 3'b010,
        STATE_MEM_WAIT = 3'b011
    } state_e;

    state_e state, state_next;

    // ------------------------------------------------------------------------
    // Registers & Program Counter
    // ------------------------------------------------------------------------
    logic [31:0] pc_q, pc_next;
    logic [31:0] instr_q;
    logic [31:0] regfile [0:31];

    // Decode signals
    logic [6:0]  opcode;
    logic [4:0]  rd;
    logic [2:0]  funct3;
    logic [4:0]  rs1;
    logic [4:0]  rs2;
    logic [6:0]  funct7;

    logic [31:0] rs1_data;
    logic [31:0] rs2_data;
    logic [31:0] imm_i;
    logic [31:0] imm_s;
    logic [31:0] imm_b;
    logic [31:0] imm_u;
    logic [31:0] imm_j;

    // Execution signals
    logic [31:0] alu_result;
    logic        reg_write_en;
    logic [31:0] reg_write_data;
    logic        branch_taken;

    // ------------------------------------------------------------------------
    // Instruction Fields Breakdown
    // ------------------------------------------------------------------------
    assign opcode = instr_q[6:0];
    assign rd     = instr_q[11:7];
    assign funct3 = instr_q[14:12];
    assign rs1    = instr_q[19:15];
    assign rs2    = instr_q[24:20];
    assign funct7 = instr_q[31:25];

    // Sign-extended immediates
    assign imm_i = {{20{instr_q[31]}}, instr_q[31:20]};
    assign imm_s = {{20{instr_q[31]}}, instr_q[31:25], instr_q[11:7]};
    assign imm_b = {{19{instr_q[31]}}, instr_q[31], instr_q[7], instr_q[30:25], instr_q[11:8], 1'b0};
    assign imm_u = {instr_q[31:12], 12'h000};
    assign imm_j = {{11{instr_q[31]}}, instr_q[31], instr_q[19:12], instr_q[20], instr_q[30:21], 1'b0};

    // Register file read (x0 is hardwired to 0)
    assign rs1_data = (rs1 == 5'd0) ? 32'd0 : regfile[rs1];
    assign rs2_data = (rs2 == 5'd0) ? 32'd0 : regfile[rs2];

    // ------------------------------------------------------------------------
    // ALU Operations
    // ------------------------------------------------------------------------
    logic [31:0] alu_op_a;
    logic [31:0] alu_op_b;
    logic [4:0]  shift_amt;

    assign shift_amt = alu_op_b[4:0];

    always_comb begin
        case (opcode)
            7'b0110011: begin // Register-Register (ADD, SUB, AND, OR, XOR, SLL, SRL, SRA, SLT, SLTU)
                alu_op_a = rs1_data;
                alu_op_b = rs2_data;
            end
            7'b0010011: begin // Immediate (ADDI, ANDI, ORI, XORI, SLLI, SRLI, SRAI, SLTI, SLTIU)
                alu_op_a = rs1_data;
                alu_op_b = imm_i;
            end
            7'b0000011, // Load (LW, LH, LHU, LB, LBU)
            7'b0100011: begin // Store (SW, SH, SB)
                alu_op_a = rs1_data;
                alu_op_b = (opcode == 7'b0000011) ? imm_i : imm_s;
            end
            7'b0110111: begin // LUI
                alu_op_a = 32'd0;
                alu_op_b = imm_u;
            end
            7'b0010111: begin // AUIPC
                alu_op_a = pc_q;
                alu_op_b = imm_u;
            end
            default: begin
                alu_op_a = rs1_data;
                alu_op_b = imm_i;
            end
        endcase
    end

    always_comb begin
        if (opcode == 7'b0000011 || opcode == 7'b0100011 || opcode == 7'b0110111 || opcode == 7'b0010111) begin
            alu_result = alu_op_a + alu_op_b; // Memory Address / LUI / AUIPC
        end else begin
            case (funct3)
                3'b000: begin
                    if (opcode == 7'b0110011 && funct7[5]) begin
                        alu_result = alu_op_a - alu_op_b; // SUB
                    end else begin
                        alu_result = alu_op_a + alu_op_b; // ADD / ADDI
                    end
                end
                3'b001: alu_result = alu_op_a << shift_amt; // SLL / SLLI
                3'b010: alu_result = ($signed(alu_op_a) < $signed(alu_op_b)) ? 32'd1 : 32'd0; // SLT / SLTI
                3'b011: alu_result = (alu_op_a < alu_op_b) ? 32'd1 : 32'd0; // SLTU / SLTIU
                3'b100: alu_result = alu_op_a ^ alu_op_b; // XOR / XORI
                3'b101: begin
                    if (funct7[5]) begin
                        alu_result = $signed(alu_op_a) >>> shift_amt; // SRA / SRAI
                    end else begin
                        alu_result = alu_op_a >> shift_amt; // SRL / SRLI
                    end
                end
                3'b110: alu_result = alu_op_a | alu_op_b; // OR / ORI
                3'b111: alu_result = alu_op_a & alu_op_b; // AND / ANDI
                default: alu_result = 32'd0;
            endcase
        end
    end

    // ------------------------------------------------------------------------
    // Branch Evaluation
    // ------------------------------------------------------------------------
    always_comb begin
        case (funct3)
            3'b000: branch_taken = (rs1_data == rs2_data); // BEQ
            3'b001: branch_taken = (rs1_data != rs2_data); // BNE
            3'b100: branch_taken = ($signed(rs1_data) < $signed(rs2_data)); // BLT
            3'b101: branch_taken = ($signed(rs1_data) >= $signed(rs2_data)); // BGE
            3'b110: branch_taken = (rs1_data < rs2_data); // BLTU
            3'b111: branch_taken = (rs1_data >= rs2_data); // BGEU
            default: branch_taken = 1'b0;
        endcase
    end

    // ------------------------------------------------------------------------
    // Memory Interface Outputs
    // ------------------------------------------------------------------------
    assign instr_addr_o = pc_q;
    assign instr_req_o  = (state == STATE_FETCH);

    assign data_addr_o  = alu_result;
    assign data_req_o   = (state == STATE_EXECUTE || state == STATE_MEM_WAIT) && ((opcode == 7'b0000011) || (opcode == 7'b0100011));
    assign data_we_o    = (opcode == 7'b0100011);

    // Byte enables and store data formatting
    always_comb begin
        case (funct3[1:0])
            2'b00: begin // SB
                data_be_o = 4'b0001 << alu_result[1:0];
                data_wdata_o = {4{rs2_data[7:0]}};
            end
            2'b01: begin // SH
                data_be_o = alu_result[1] ? 4'b1100 : 4'b0011;
                data_wdata_o = {2{rs2_data[15:0]}};
            end
            default: begin // SW (2'b10)
                data_be_o = 4'b1111;
                data_wdata_o = rs2_data;
            end
        endcase
    end

    // ------------------------------------------------------------------------
    // Register Writeback Formatting
    // ------------------------------------------------------------------------
    logic [31:0] load_data_formatted;
    always_comb begin
        case (funct3)
            3'b000: begin // LB
                case (alu_result[1:0])
                    2'b00: load_data_formatted = {{24{data_rdata_i[7]}},  data_rdata_i[7:0]};
                    2'b01: load_data_formatted = {{24{data_rdata_i[15]}}, data_rdata_i[15:8]};
                    2'b10: load_data_formatted = {{24{data_rdata_i[23]}}, data_rdata_i[23:16]};
                    2'b11: load_data_formatted = {{24{data_rdata_i[31]}}, data_rdata_i[31:24]};
                endcase
            end
            3'b001: begin // LH
                load_data_formatted = alu_result[1] ? {{16{data_rdata_i[31]}}, data_rdata_i[31:16]}
                                                    : {{16{data_rdata_i[15]}}, data_rdata_i[15:0]};
            end
            3'b010: begin // LW
                load_data_formatted = data_rdata_i;
            end
            3'b100: begin // LBU
                case (alu_result[1:0])
                    2'b00: load_data_formatted = {24'd0, data_rdata_i[7:0]};
                    2'b01: load_data_formatted = {24'd0, data_rdata_i[15:8]};
                    2'b10: load_data_formatted = {24'd0, data_rdata_i[23:16]};
                    2'b11: load_data_formatted = {24'd0, data_rdata_i[31:24]};
                endcase
            end
            3'b101: begin // LHU
                load_data_formatted = alu_result[1] ? {16'd0, data_rdata_i[31:16]}
                                                    : {16'd0, data_rdata_i[15:0]};
            end
            default: load_data_formatted = data_rdata_i;
        endcase
    end

    // ------------------------------------------------------------------------
    // FSM State & Datapath Next Logic
    // ------------------------------------------------------------------------
    always_comb begin
        state_next    = state;
        pc_next       = pc_q;
        reg_write_en  = 1'b0;
        reg_write_data = 32'd0;
        irq_ack_o     = 1'b0;

        case (state)
            STATE_FETCH: begin
                if (instr_valid_i) begin
                    state_next = STATE_DECODE;
                end
            end

            STATE_DECODE: begin
                state_next = STATE_EXECUTE;
            end

            STATE_EXECUTE: begin
                case (opcode)
                    7'b0110011, // R-type
                    7'b0010011, // I-type ALU
                    7'b0110111, // LUI
                    7'b0010111: begin // AUIPC
                        reg_write_en   = (rd != 5'd0);
                        reg_write_data = alu_result;
                        pc_next        = pc_q + 32'd4;
                        state_next     = STATE_FETCH;
                    end

                    7'b1101111: begin // JAL
                        reg_write_en   = (rd != 5'd0);
                        reg_write_data = pc_q + 32'd4;
                        pc_next        = pc_q + imm_j;
                        state_next     = STATE_FETCH;
                    end

                    7'b1100111: begin // JALR
                        reg_write_en   = (rd != 5'd0);
                        reg_write_data = pc_q + 32'd4;
                        pc_next        = (rs1_data + imm_i) & ~32'd1;
                        state_next     = STATE_FETCH;
                    end

                    7'b1100011: begin // BRANCH
                        pc_next    = branch_taken ? (pc_q + imm_b) : (pc_q + 32'd4);
                        state_next = STATE_FETCH;
                    end

                    7'b0000011: begin // LOAD
                        if (data_valid_i) begin
                            reg_write_en   = (rd != 5'd0);
                            reg_write_data = load_data_formatted;
                            pc_next        = pc_q + 32'd4;
                            state_next     = STATE_FETCH;
                        end else begin
                            state_next     = STATE_MEM_WAIT;
                        end
                    end

                    7'b0100011: begin // STORE
                        if (data_valid_i) begin
                            pc_next        = pc_q + 32'd4;
                            state_next     = STATE_FETCH;
                        end else begin
                            state_next     = STATE_MEM_WAIT;
                        end
                    end

                    default: begin // NOP / Unsupported
                        pc_next    = pc_q + 32'd4;
                        state_next = STATE_FETCH;
                    end
                endcase
            end

            STATE_MEM_WAIT: begin
                if (data_valid_i) begin
                    if (opcode == 7'b0000011) begin // LOAD writeback
                        reg_write_en   = (rd != 5'd0);
                        reg_write_data = load_data_formatted;
                    end
                    pc_next    = pc_q + 32'd4;
                    state_next = STATE_FETCH;
                end
            end

            default: state_next = STATE_FETCH;
        endcase
    end

    // ------------------------------------------------------------------------
    // Sequential Registers Update
    // ------------------------------------------------------------------------
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state   <= STATE_FETCH;
            pc_q    <= BOOT_ADDR;
            instr_q <= 32'h0000_0013; // NOP (addi x0, x0, 0)
        end else begin
            state <= state_next;
            pc_q  <= pc_next;

            if (state == STATE_FETCH && instr_valid_i) begin
                instr_q <= instr_data_i;
            end

            if (reg_write_en && (rd != 5'd0)) begin
                regfile[rd] <= reg_write_data;
            end
        end
    end

endmodule : riscv_core_rv32i
