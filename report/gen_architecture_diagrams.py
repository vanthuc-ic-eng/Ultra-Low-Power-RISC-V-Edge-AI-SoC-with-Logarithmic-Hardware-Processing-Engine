#!/usr/bin/env python3
# -*- coding: utf-8 -*-
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
import matplotlib.patches as patches

# Professional color palette for IEEE VLSI/Architecture papers
C_CPU = '#d0e1fd'       # Light blue
C_BUS = '#ffe6cc'       # Light orange
C_HWPE = '#d5e8d4'      # Light green
C_MEM = '#f8cecc'       # Light pink/red
C_PE = '#e1d5e7'        # Light purple
C_PIPE = '#fff2cc'      # Highlight yellow
C_BORDER = '#333333'

def draw_soc_arch(out_path):
    fig, ax = plt.subplots(figsize=(7.1, 3.4), dpi=300)
    ax.set_xlim(0, 100)
    ax.set_ylim(0, 50)
    ax.axis('off')

    # Main SoC Boundary Box
    soc_box = patches.FancyBboxPatch((1, 1), 98, 48, boxstyle="round,pad=0.5",
                                     edgecolor='#2b5b84', facecolor='#fbfbfd', linewidth=1.5, linestyle='--')
    ax.add_patch(soc_box)
    ax.text(3, 46.5, "Mini-PULP Edge AI System-on-Chip (AMD Xilinx Zynq-7000 xc7z010)",
            fontsize=8.5, fontweight='bold', color='#2b5b84')

    # 1. Host Control Plane (RV32I CPU)
    cpu_box = patches.FancyBboxPatch((3, 23), 22, 21, boxstyle="round,pad=0.3",
                                     edgecolor='#3b75af', facecolor=C_CPU, linewidth=1.2)
    ax.add_patch(cpu_box)
    ax.text(14, 41.5, "RISC-V Host CPU\n(RV32I Core)", ha='center', va='center', fontsize=8, fontweight='bold')
    
    # CPU Submodules
    ax.add_patch(patches.Rectangle((4.5, 32), 19, 5.5, facecolor='#ffffff', edgecolor='#3b75af', linewidth=0.8))
    ax.text(14, 34.7, "Fetch & L1 Boot ROM\n(4KB Hex Firmware)", ha='center', va='center', fontsize=6.5)

    ax.add_patch(patches.Rectangle((4.5, 24.5), 19, 6.2, facecolor=C_PIPE, edgecolor='#e6ac00', linewidth=0.9))
    ax.text(14, 27.6, "Decode Stage (Reg Latch)\n& 32-bit ALU Datapath", ha='center', va='center', fontsize=6.8, fontweight='bold')

    # 2. UART Peripheral
    uart_box = patches.FancyBboxPatch((3, 4), 22, 14, boxstyle="round,pad=0.3",
                                      edgecolor='#7f7f7f', facecolor='#f5f5f5', linewidth=1.0)
    ax.add_patch(uart_box)
    ax.text(14, 15, "UART Serial Tx (115.2k)", ha='center', va='center', fontsize=7.5, fontweight='bold')
    ax.text(14, 9, "Baud Generator +\nByte Shift Register\n[Real-Time Output]", ha='center', va='center', fontsize=6.5)

    # 3. System Bus Crossbar / Interconnect
    bus_box = patches.FancyBboxPatch((28, 4), 6, 40, boxstyle="round,pad=0.2",
                                     edgecolor='#d79b00', facecolor=C_BUS, linewidth=1.2)
    ax.add_patch(bus_box)
    ax.text(31, 24, "S\nO\nC\n \nB\nU\nS\n \nC\nR\nO\nS\nS\nB\nA\nR",
            ha='center', va='center', fontsize=7, fontweight='bold', color='#804000')

    # Connecting Arrows CPU <-> Bus <-> UART
    ax.annotate('', xy=(28, 33), xytext=(25, 33), arrowprops=dict(arrowstyle="<->", lw=1.2, color='#3b75af'))
    ax.text(26.5, 34.5, "dmem", fontsize=6, ha='center')
    ax.annotate('', xy=(28, 11), xytext=(25, 11), arrowprops=dict(arrowstyle="<-", lw=1.2, color='#555555'))

    # 4. HWPE Subsystem Boundary Box
    hwpe_box = patches.FancyBboxPatch((37, 3), 60, 42, boxstyle="round,pad=0.4",
                                      edgecolor='#274e13', facecolor=C_HWPE, linewidth=1.3)
    ax.add_patch(hwpe_box)
    ax.text(67, 43.5, "Autonomous Hardware Processing Engine (LA-HWPE V2 Accelerator)",
            ha='center', va='center', fontsize=8.2, fontweight='bold', color='#1e4620')

    # Bus <-> CSR
    ax.annotate('', xy=(40, 36), xytext=(34, 36), arrowprops=dict(arrowstyle="<->", lw=1.2, color='#d79b00'))

    # CSR Wrapper
    csr_box = patches.Rectangle((40, 32), 15, 8, facecolor='#ffffff', edgecolor='#274e13', linewidth=0.9)
    ax.add_patch(csr_box)
    ax.text(47.5, 36, "Memory-Mapped\nCSR Wrapper", ha='center', va='center', fontsize=6.8, fontweight='bold')

    # Stream Controller & AGU
    ctrl_box = patches.Rectangle((40, 18), 15, 11, facecolor=C_PIPE, edgecolor='#b45f06', linewidth=1.0)
    ax.add_patch(ctrl_box)
    ax.text(47.5, 23.5, "HWPE Stream AGU\nZero-Bubble FSM\n(3-Cycle Drain)", ha='center', va='center', fontsize=6.8, fontweight='bold')

    # Argmax Unit
    argmax_box = patches.Rectangle((40, 5.5), 15, 9.5, facecolor='#ffffff', edgecolor='#274e13', linewidth=0.9)
    ax.add_patch(argmax_box)
    ax.text(47.5, 10.2, "2-Stage Binary Tree\nArgmax (0..9 Class)", ha='center', va='center', fontsize=6.8, fontweight='bold')

    # 5. TCDM Multi-Banked Memory
    tcdm_box = patches.FancyBboxPatch((59, 23), 36, 17, boxstyle="round,pad=0.2",
                                      edgecolor='#b85450', facecolor=C_MEM, linewidth=1.1)
    ax.add_patch(tcdm_box)
    ax.text(77, 38, "TCDM Multi-Banked On-Chip SRAM (51 KB Total)", ha='center', va='center', fontsize=7.2, fontweight='bold', color='#900')

    ax.add_patch(patches.Rectangle((60.5, 25), 10.5, 10.5, facecolor='#ffffff', edgecolor='#b85450', linewidth=0.8))
    ax.text(65.7, 30.2, "Activation\nSRAM (1 KB)\n[Ping-Pong]", ha='center', va='center', fontsize=6)

    ax.add_patch(patches.Rectangle((72.5, 25), 11.5, 10.5, facecolor='#ffffff', edgecolor='#b85450', linewidth=0.8))
    ax.text(78.2, 30.2, "Weight BRAM\n(49.2 KB)\n[48-bit bus]", ha='center', va='center', fontsize=6, fontweight='bold')

    ax.add_patch(patches.Rectangle((85.5, 25), 8, 10.5, facecolor='#ffffff', edgecolor='#b85450', linewidth=0.8))
    ax.text(89.5, 30.2, "Bias\nROM\n(0.8KB)", ha='center', va='center', fontsize=6)

    # 6. 1x4 Output-Stationary Compute Engine
    eng_box = patches.FancyBboxPatch((59, 5.5), 36, 15, boxstyle="round,pad=0.2",
                                     edgecolor='#6c8ebf', facecolor=C_PE, linewidth=1.1)
    ax.add_patch(eng_box)
    ax.text(77, 18.5, "1x4 SIMD Zero-DSP Log-Arithmetic Engine", ha='center', va='center', fontsize=7.2, fontweight='bold', color='#3c5a8a')

    # Shared LOD
    ax.add_patch(patches.Rectangle((60.5, 7.5), 8, 9, facecolor='#ffffff', edgecolor='#6c8ebf', linewidth=0.8))
    ax.text(64.5, 12, "Shared Act\nLog LOD\nEncoder", ha='center', va='center', fontsize=6, fontweight='bold')

    # 4 PEs
    for i in range(4):
        x_pe = 70 + i * 5.8
        ax.add_patch(patches.Rectangle((x_pe, 7.5), 5.2, 9, facecolor=C_PIPE, edgecolor='#b45f06', linewidth=0.8))
        ax.text(x_pe + 2.6, 12, f"PE_{i}\nMAC\nPipe", ha='center', va='center', fontsize=5.8, fontweight='bold')

    # Connections inside HWPE
    ax.annotate('', xy=(64.5, 25), xytext=(64.5, 16.5), arrowprops=dict(arrowstyle="<->", lw=1.0, color='#333333'))
    ax.annotate('', xy=(78, 25), xytext=(78, 16.5), arrowprops=dict(arrowstyle="->", lw=1.2, color='#b85450'))
    ax.annotate('', xy=(55, 10.2), xytext=(59, 10.2), arrowprops=dict(arrowstyle="<-", lw=1.1, color='#274e13'))
    ax.text(57, 11.5, "4xLogits", fontsize=5.5, ha='center')

    # Controller controls
    ax.annotate('', xy=(55, 23.5), xytext=(59, 27), arrowprops=dict(arrowstyle="<-", lw=0.9, linestyle=":", color='#b45f06'))
    ax.annotate('', xy=(55, 20), xytext=(69, 13), arrowprops=dict(arrowstyle="<-", lw=0.9, linestyle=":", color='#b45f06'))

    plt.savefig(out_path, format='pdf', bbox_inches='tight')
    plt.close()
    print(f"[+] Saved: {out_path}")

def draw_pe_datapath(out_path):
    fig, ax = plt.subplots(figsize=(4.8, 2.7), dpi=300)
    ax.set_xlim(0, 100)
    ax.set_ylim(0, 60)
    ax.axis('off')

    # Title
    ax.text(50, 57, "Pipelined 1-Cycle Zero-DSP Processing Element (PE MAC)",
            fontsize=8.5, fontweight='bold', ha='center', color='#1a365d')

    # Stage 1: Multiplication (Log domain)
    stg1_box = patches.FancyBboxPatch((2, 18), 44, 36, boxstyle="round,pad=0.3",
                                      edgecolor='#4a5568', facecolor='#edf2f7', linewidth=1.0)
    ax.add_patch(stg1_box)
    ax.text(24, 51.5, "Stage 1: Zero-LOD Multiplier (4.5 ns)", ha='center', va='center', fontsize=7.2, fontweight='bold', color='#2d3748')

    # Inputs
    ax.text(4, 43, "Act (LOD)\n[9-bit]", fontsize=6, ha='left')
    ax.annotate('', xy=(12, 43), xytext=(8, 43), arrowprops=dict(arrowstyle="->", lw=1))

    ax.text(4, 31, "Weight\n[12-bit]", fontsize=6, ha='left', fontweight='bold', color='#900')
    ax.annotate('', xy=(12, 31), xytext=(8, 31), arrowprops=dict(arrowstyle="->", lw=1))

    # 9-bit Adder
    ax.add_patch(patches.Rectangle((12, 28), 12, 18, facecolor='#ffffff', edgecolor='#3182ce', linewidth=0.9))
    ax.text(18, 37, "9-bit Log\nAdder\n(Low4 LUT)", ha='center', va='center', fontsize=6.2)

    # Antilog Shifter
    ax.annotate('', xy=(28, 37), xytext=(24, 37), arrowprops=dict(arrowstyle="->", lw=1))
    ax.add_patch(patches.Rectangle((28, 28), 15, 18, facecolor='#ffffff', edgecolor='#3182ce', linewidth=0.9))
    ax.text(35.5, 37, "Antilog\nBarrel\nShifter", ha='center', va='center', fontsize=6.2)

    # Pipeline Register Boundary
    pipe_box = patches.FancyBboxPatch((49, 10), 10, 44, boxstyle="round,pad=0.2",
                                      edgecolor='#b7791f', facecolor='#fefcbf', linewidth=1.2)
    ax.add_patch(pipe_box)
    ax.text(54, 32, "P\nI\nP\nE\nL\nI\nN\nE\n \nR\nE\nG", ha='center', va='center', fontsize=6.8, fontweight='bold', color='#744210')

    ax.annotate('', xy=(49, 37), xytext=(43, 37), arrowprops=dict(arrowstyle="->", lw=1.2, color='#b7791f'))
    ax.text(46, 39, "prod_w", fontsize=5.5, ha='center')

    # Stage 2: 32-bit Accumulator
    stg2_box = patches.FancyBboxPatch((62, 10), 36, 44, boxstyle="round,pad=0.3",
                                      edgecolor='#2b6cb0', facecolor='#ebf8ff', linewidth=1.0)
    ax.add_patch(stg2_box)
    ax.text(80, 51.5, "Stage 2: 32-bit Acc (3.0 ns)", ha='center', va='center', fontsize=7.2, fontweight='bold', color='#2b6cb0')

    # Pipeline output to adder
    ax.annotate('', xy=(67, 37), xytext=(59, 37), arrowprops=dict(arrowstyle="->", lw=1.2, color='#b7791f'))
    ax.text(63, 39, "prod_q", fontsize=5.8, ha='center', fontweight='bold')

    # 32-bit Adder
    ax.add_patch(patches.Rectangle((67, 30), 11, 14, facecolor='#ffffff', edgecolor='#2b6cb0', linewidth=0.9))
    ax.text(72.5, 37, "32-bit\nAdder", ha='center', va='center', fontsize=6.5, fontweight='bold')

    # Acc Register
    ax.annotate('', xy=(82, 37), xytext=(78, 37), arrowprops=dict(arrowstyle="->", lw=1.1))
    ax.add_patch(patches.Rectangle((82, 28), 13, 18, facecolor=C_PIPE, edgecolor='#2b6cb0', linewidth=1.1))
    ax.text(88.5, 37, "acc_o\n(32-bit FF)\n[Bias Load]", ha='center', va='center', fontsize=6.2, fontweight='bold')

    # Feedback loop
    ax.annotate('', xy=(72.5, 30), xytext=(88.5, 28),
                arrowprops=dict(arrowstyle="->", lw=0.9, linestyle="--", connectionstyle="arc3,rad=-0.4", color='#2b6cb0'))
    ax.text(80, 21, "Accumulator Feedback", fontsize=5.2, ha='center', color='#2b6cb0')

    # Fused Requant-ReLU
    ax.annotate('', xy=(88.5, 10), xytext=(88.5, 28), arrowprops=dict(arrowstyle="->", lw=1.1))
    ax.add_patch(patches.Rectangle((75, 2), 22, 7.5, facecolor='#ffffff', edgecolor='#274e13', linewidth=0.9))
    ax.text(86, 5.7, "Fused Requant-ReLU (INT8)", ha='center', va='center', fontsize=6, fontweight='bold')

    plt.savefig(out_path, format='pdf', bbox_inches='tight')
    plt.close()
    print(f"[+] Saved: {out_path}")

def draw_gui_demo(out_path):
    fig, ax = plt.subplots(figsize=(4.8, 1.8), dpi=300)
    ax.set_xlim(0, 100)
    ax.set_ylim(0, 36)
    ax.axis('off')

    # Workflow Steps
    steps = [
        ("1. Canvas Draw\n(280x280 User Input)", '#e2e8f0', 2),
        ("2. Centering & Crop\n(Center-of-Mass 20x20)", '#feebc8', 27),
        ("3. MNIST 28x28\n(INT8 Log-Weights)", '#c6f6d5', 52),
        ("4. SoC Inference\n(127.96 us @ 100MHz)", '#bee3f8', 77)
    ]

    for title, col, x in steps:
        box = patches.FancyBboxPatch((x, 4), 21, 28, boxstyle="round,pad=0.2",
                                     edgecolor='#4a5568', facecolor=col, linewidth=1.0)
        ax.add_patch(box)
        ax.text(x + 10.5, 18, title, ha='center', va='center', fontsize=6.5, fontweight='bold')

    # Arrows between steps
    ax.annotate('', xy=(26, 18), xytext=(24, 18), arrowprops=dict(arrowstyle="->", lw=1.2))
    ax.annotate('', xy=(51, 18), xytext=(49, 18), arrowprops=dict(arrowstyle="->", lw=1.2))
    ax.annotate('', xy=(76, 18), xytext=(74, 18), arrowprops=dict(arrowstyle="->", lw=1.2))

    plt.savefig(out_path, format='pdf', bbox_inches='tight')
    plt.close()
    print(f"[+] Saved: {out_path}")

if __name__ == '__main__':
    draw_soc_arch('/workspace/projects/pulp_edge_ai_soc/report/figures/fig_soc_arch.pdf')
    draw_pe_datapath('/workspace/projects/pulp_edge_ai_soc/report/figures/fig_pe_datapath.pdf')
    draw_gui_demo('/workspace/projects/pulp_edge_ai_soc/report/figures/fig_gui_demo.pdf')
