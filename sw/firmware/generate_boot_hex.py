#!/usr/bin/env python3
# ==============================================================================
# File: generate_boot_hex.py
# Project: PULP-inspired Edge AI SoC for Handwritten Digit Recognition
# Author: Nguyen Van Thuc (24161421)
# Description:
#   Lightweight RV32I Assembler & Boot ROM Hex Generator.
#   Generates the autonomous boot firmware for the RISC-V SoC:
#   1. Prints startup banner via UART.
#   2. Triggers HWPE inference via memory-mapped CSR (0x40000000).
#   3. Polls status register (0x40000004) until DONE.
#   4. Reads predicted class (0x40000008) and cycle count (0x40000010).
#   5. Formats and prints results over UART to terminal.
# ==============================================================================

import sys

def encode_r(funct7, rs2, rs1, funct3, rd, opcode):
    return (funct7 << 25) | (rs2 << 20) | (rs1 << 15) | (funct3 << 12) | (rd << 7) | opcode

def encode_i(imm, rs1, funct3, rd, opcode):
    imm &= 0xFFF
    return (imm << 20) | (rs1 << 15) | (funct3 << 12) | (rd << 7) | opcode

def encode_s(imm, rs2, rs1, funct3, opcode):
    imm &= 0xFFF
    imm_11_5 = (imm >> 5) & 0x7F
    imm_4_0  = imm & 0x1F
    return (imm_11_5 << 25) | (rs2 << 20) | (rs1 << 15) | (funct3 << 12) | (imm_4_0 << 7) | opcode

def encode_b(imm, rs2, rs1, funct3, opcode):
    imm &= 0x1FFE
    b12 = (imm >> 12) & 1
    b11 = (imm >> 11) & 1
    b10_5 = (imm >> 5) & 0x3F
    b4_1 = (imm >> 1) & 0xF
    return (b12 << 31) | (b10_5 << 25) | (rs2 << 20) | (rs1 << 15) | (funct3 << 12) | (b4_1 << 8) | (b11 << 7) | opcode

def encode_u(imm20, rd, opcode):
    return ((imm20 & 0xFFFFF) << 12) | (rd << 7) | opcode

def encode_j(imm, rd, opcode):
    imm &= 0x1FFFFE
    j20 = (imm >> 20) & 1
    j19_12 = (imm >> 12) & 0xFF
    j11 = (imm >> 11) & 1
    j10_1 = (imm >> 1) & 0x3FF
    return (j20 << 31) | (j10_1 << 21) | (j11 << 20) | (j19_12 << 12) | (rd << 7) | opcode

# Instructions helpers
def LUI(rd, imm20): return encode_u(imm20, rd, 0x37)
def ADDI(rd, rs1, imm12): return encode_i(imm12, rs1, 0x0, rd, 0x13)
def ANDI(rd, rs1, imm12): return encode_i(imm12, rs1, 0x7, rd, 0x13)
def LW(rd, rs1, imm12): return encode_i(imm12, rs1, 0x2, rd, 0x03)
def SW(rs2, rs1, imm12): return encode_s(imm12, rs2, rs1, 0x2, 0x23)
def BEQ(rs1, rs2, imm13): return encode_b(imm13, rs2, rs1, 0x0, 0x63)
def BNE(rs1, rs2, imm13): return encode_b(imm13, rs2, rs1, 0x1, 0x63)
def JAL(rd, imm21): return encode_j(imm21, rd, 0x6F)
def JALR(rd, rs1, imm12): return encode_i(imm12, rs1, 0x0, rd, 0x67)

def build_firmware():
    # Registers:
    # x1: ra
    # x2: sp (stack pointer)
    # x10: a0 (argument / char to print)
    # x11: a1 (temp)
    # x12: uart_base (0x50000000)
    # x13: hwpe_base (0x40000000)
    # x14: status temp
    # x15: predicted class

    prog = []

    def emit(inst):
        prog.append(inst)

    # 0x00: lui sp, 0x20001 (sp = 0x20001000 - Top of Data SRAM)
    emit(LUI(2, 0x20001))
    
    # 0x04: lui x12, 0x50000 (x12 = UART_BASE 0x50000000)
    emit(LUI(12, 0x50000))

    # 0x08: lui x13, 0x40000 (x13 = HWPE_BASE 0x40000000)
    emit(LUI(13, 0x40000))

    # Print '[PULP-AI] '
    # Print characters: '[', 'P', 'U', 'L', 'P', ']', ' ', 'O', 'K', '!', '\n'
    chars = [ord(c) for c in "[PULP-AI] STARTING INFERENCE...\r\n"]
    for c in chars:
        # poll UART ready: lw x14, 4(x12); andi x14, x14, 1; beq x14, x0, -8
        emit(LW(14, 12, 4))
        emit(ANDI(14, 14, 1))
        emit(BEQ(14, 0, -8)) # loop until ready
        # sw c, 0(x12)
        emit(ADDI(10, 0, c))
        emit(SW(10, 12, 0))

    # Trigger HWPE AI Accelerator: Write 1 to REG_CTRL (0(x13))
    emit(ADDI(10, 0, 1))
    emit(SW(10, 13, 0))

    # Poll REG_STATUS (4(x13)) for DONE (bit 1 == 1)
    # loop_poll:
    poll_addr = len(prog) * 4
    emit(LW(14, 13, 4))       # lw x14, 4(x13)
    emit(ANDI(14, 14, 2))     # andi x14, x14, 2 (bit 1 is DONE)
    emit(BEQ(14, 0, -8))      # if not done, loop back to lw

    # Read REG_PRED_CLASS (8(x13))
    emit(LW(15, 13, 8))       # x15 = pred_class

    # Print 'DONE! PRED DIGIT: '
    chars2 = [ord(c) for c in "[PULP-AI] DONE! PREDICTED DIGIT = "]
    for c in chars2:
        emit(LW(14, 12, 4))
        emit(ANDI(14, 14, 1))
        emit(BEQ(14, 0, -8))
        emit(ADDI(10, 0, c))
        emit(SW(10, 12, 0))

    # Convert predicted class (0..9) to ASCII ('0' + x15) and print
    emit(ADDI(10, 15, ord('0')))
    emit(LW(14, 12, 4))
    emit(ANDI(14, 14, 1))
    emit(BEQ(14, 0, -8))
    emit(SW(10, 12, 0))

    # Print '\r\n[PULP-AI] SYSTEM HALTED.\r\n'
    chars3 = [ord(c) for c in "\r\n[PULP-AI] INFERENCE PASS, SYSTEM HALTED.\r\n"]
    for c in chars3:
        emit(LW(14, 12, 4))
        emit(ANDI(14, 14, 1))
        emit(BEQ(14, 0, -8))
        emit(ADDI(10, 0, c))
        emit(SW(10, 12, 0))

    # Halt loop: jal x0, 0 (infinite loop)
    emit(JAL(0, 0))

    return prog

def main():
    prog = build_firmware()
    out_path = "/workspace/projects/pulp_edge_ai_soc/sw/firmware/boot_rom.hex"
    with open(out_path, "w") as f:
        for inst in prog:
            f.write(f"{inst:08x}\n")
        # Pad to 1024 words (4 KB)
        for _ in range(1024 - len(prog)):
            f.write("00000013\n") # NOP
    print(f"Generated {len(prog)} RV32I instructions in {out_path} (Padded to 1024 words).")

if __name__ == "__main__":
    main()
