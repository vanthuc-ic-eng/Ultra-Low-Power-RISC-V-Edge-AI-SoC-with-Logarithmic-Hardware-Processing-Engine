#!/usr/bin/env python3
# -*- coding: utf-8 -*-
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
import numpy as np

# Set font styling for IEEE paper
plt.rcParams.update({
    'font.family': 'serif',
    'font.size': 9,
    'axes.labelsize': 9,
    'axes.titlesize': 9.5,
    'xtick.labelsize': 8,
    'ytick.labelsize': 8,
    'legend.fontsize': 7.5,
    'figure.titlesize': 10,
    'pdf.fonttype': 42,
    'ps.fonttype': 42
})

def gen_fig3_scaling(out_path):
    freqs = np.array([50, 75, 100, 125, 150, 180, 200])
    fps = np.array([3907, 5861, 7815, 9769, 11722, 14067, 15630])
    power_dyn = np.array([32.0, 49.0, 65.0, 81.0, 97.0, 116.0, 129.0])
    energy = np.array([8.19, 8.36, 8.32, 8.29, 8.27, 8.25, 8.25])
    latency = np.array([255.92, 170.61, 127.96, 102.37, 85.31, 71.09, 63.98])

    fig, ax1 = plt.subplots(figsize=(4.8, 2.7), dpi=300)

    # Color palette
    color_fps = '#1f77b4'
    color_pwr = '#d62728'
    color_ene = '#2ca02c'

    # Left axis: Throughput (FPS)
    line1 = ax1.plot(freqs, fps, marker='o', linewidth=1.8, markersize=5, color=color_fps, label='Throughput (FPS)')
    ax1.set_xlabel('Operating Frequency $F_{clk}$ (MHz)', fontweight='bold')
    ax1.set_ylabel('Throughput (Frames / Sec)', color=color_fps, fontweight='bold')
    ax1.tick_params(axis='y', labelcolor=color_fps)
    ax1.grid(True, linestyle='--', alpha=0.5)

    # Highlight 100 MHz Timing Sign-Off point
    ax1.scatter([100], [7815], color='#ff7f0e', s=80, zorder=5, edgecolor='black')
    ax1.annotate('100 MHz Sign-off\n(7,815 FPS, Met)', xy=(100, 7815), xytext=(65, 10500),
                 arrowprops=dict(facecolor='black', shrink=0.08, width=1, headwidth=5),
                 fontsize=7.5, fontweight='bold', bbox=dict(boxstyle='round,pad=0.2', facecolor='#ffffcc', alpha=0.9))

    # Right axis: Dynamic Power (mW)
    ax2 = ax1.twinx()
    line2 = ax2.plot(freqs, power_dyn, marker='s', linewidth=1.6, linestyle='--', markersize=4.5, color=color_pwr, label='Dynamic Power (mW)')
    line3 = ax2.plot(freqs, energy * 10, marker='^', linewidth=1.4, linestyle=':', markersize=4.5, color=color_ene, label='Energy/Inf (x0.1 $\\mu$J)')
    ax2.set_ylabel('Power (mW) & Energy ($\\times 0.1\\,\\mu$J)', color='#800000', fontweight='bold')
    ax2.tick_params(axis='y', labelcolor='#800000')

    # Combined legend
    lines = line1 + line2 + line3
    labels = [l.get_label() for l in lines]
    ax1.legend(lines, labels, loc='upper left', framealpha=0.9)

    fig.tight_layout()
    plt.savefig(out_path, format='pdf', bbox_inches='tight')
    plt.close()
    print(f"[+] Saved: {out_path}")

def gen_fig4_hierarchy(out_path):
    labels = ['RV32I Host CPU', 'HWPE 1x4 Engine', 'TCDM SRAMs', 'CSR Wrapper', 'Interconnect & UART']
    luts = [1610, 495, 567, 235, 51] # Total 2,958 LUTs
    colors = ['#4c72b0', '#55a868', '#c44e52', '#8172b3', '#ccb974']

    fig, (ax1, ax2) = plt.subplots(1, 2, figsize=(4.8, 2.2), dpi=300, gridspec_kw={'width_ratios': [1.2, 1.0]})

    # Donut chart for LUT breakdown
    wedges, texts, autotexts = ax1.pie(luts, labels=None, autopct='%1.1f%%', startangle=140,
                                      colors=colors, pctdistance=0.72,
                                      textprops=dict(color="w", fontweight="bold", fontsize=7.5))
    centre_circle = plt.Circle((0,0), 0.52, fc='white')
    ax1.add_artist(centre_circle)
    ax1.text(0, 0, '2,958 LUTs\n(16.8%)', ha='center', va='center', fontsize=8, fontweight='bold', color='#333333')
    ax1.set_title('(a) Slice LUT Breakdown', fontsize=8.5, fontweight='bold', pad=3)

    # Bar chart for DSP usage comparison
    categories = ['Exact DSP48E1', 'Proposed LA-HWPE']
    dsp_used = [80, 0] # Zynq has 80 DSPs
    bars = ax2.bar(categories, dsp_used, color=['#d95f02', '#1b9e77'], width=0.52, edgecolor='black', linewidth=0.8)
    ax2.set_ylabel('DSP48E1 Blocks Used', fontsize=8, fontweight='bold')
    ax2.set_ylim(0, 95)
    ax2.set_title('(b) Zero-DSP vs Standard', fontsize=8.5, fontweight='bold', pad=3)
    ax2.grid(axis='y', linestyle='--', alpha=0.5)

    for bar, val in zip(bars, dsp_used):
        yval = bar.get_height()
        ax2.text(bar.get_x() + bar.get_width()/2.0, yval + 3, f'{val} DSPs\n({val/80.0*100:.0f}%)',
                 ha='center', va='bottom', fontsize=7.5, fontweight='bold')

    # Legend for Donut
    ax1.legend(wedges, labels, loc='center', bbox_to_anchor=(0.5, -0.28), ncol=2, fontsize=6.8, frameon=False)

    fig.tight_layout()
    plt.savefig(out_path, format='pdf', bbox_inches='tight')
    plt.close()
    print(f"[+] Saved: {out_path}")

if __name__ == '__main__':
    gen_fig3_scaling('/workspace/projects/pulp_edge_ai_soc/report/figures/fig_scaling.pdf')
    gen_fig4_hierarchy('/workspace/projects/pulp_edge_ai_soc/report/figures/fig_hierarchy.pdf')
