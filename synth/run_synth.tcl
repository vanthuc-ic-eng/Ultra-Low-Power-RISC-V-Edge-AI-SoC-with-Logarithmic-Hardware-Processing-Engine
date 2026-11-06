# ==============================================================================
# File: run_synth.tcl
# Project: PULP-inspired Edge AI SoC for Handwritten Digit Recognition
# Target Part: AMD Xilinx Zynq-7000 xc7z010clg400-1 (Digilent Zybo Z7-10)
# Author: Nguyen Van Thuc (24161421)
# Description:
#   Full Physical Synthesis, Place & Route, and Comprehensive Multi-Dimensional
#   Sign-Off Reporting (Area, Hierarchy, Timing, Critical Path, Power & Multi-Freq).
# ==============================================================================

set_param general.maxThreads 4

set proj_dir "/workspace/projects/pulp_edge_ai_soc"
set rpt_dir  "$proj_dir/synth/reports"
file mkdir $rpt_dir

create_project -in_memory -part xc7z010clg400-1

# Read SystemVerilog Package
read_verilog -sv $proj_dir/rtl/pkg/pulp_hwpe_pkg.sv

# Read SystemVerilog RTL modules (including core, memory, controller, top, soc)
read_verilog -sv [glob $proj_dir/rtl/core/*.sv]
read_verilog -sv [glob $proj_dir/rtl/memory/*.sv]
read_verilog -sv [glob $proj_dir/rtl/controller/*.sv]
read_verilog -sv [glob $proj_dir/rtl/top/*.sv]
read_verilog -sv [glob $proj_dir/rtl/soc/*.sv]

# Read XDC timing constraints
read_xdc $proj_dir/synth/constrs.xdc

# 1. Synthesis (Out of context)
puts "\n==> STEP 1/4: Running Vivado Synthesis (Top: pulp_riscv_ai_soc_top)..."
synth_design -top pulp_riscv_ai_soc_top -part xc7z010clg400-1 -mode out_of_context

# 2. Physical Optimization & Implementation
puts "\n==> STEP 2/4: Running Physical Optimization (opt_design)..."
opt_design

puts "\n==> STEP 3/4: Running Placement (place_design)..."
place_design

puts "\n==> STEP 4/4: Running Routing (route_design)..."
route_design

# 3. Comprehensive Sign-off Reporting
puts "\n==> REPORTS: Generating Comprehensive Multi-Dimensional Physical Reports..."

# A. Resource Utilization (Overall & Hierarchical Breakdown)
report_utilization -file "$rpt_dir/pnr_util.rpt"
report_utilization -file "$rpt_dir/utilization.rpt"
report_utilization -hierarchical -file "$rpt_dir/pnr_util_hierarchical.rpt"

# B. Sign-Off Timing & Critical Path Analysis at 180 MHz Constraint
report_timing_summary -delay_type min_max -max_paths 10 -file "$rpt_dir/pnr_timing_180mhz.rpt"
report_timing_summary -delay_type min_max -max_paths 10 -file "$rpt_dir/timing.rpt"
report_timing -nworst 1 -max_paths 1 -file "$rpt_dir/critical_path.rpt"

# C. Power Estimation at 180 MHz
report_power -file "$rpt_dir/pnr_power_180mhz.rpt"
report_power -file "$rpt_dir/power.rpt"

# D. Design Rule Check & Clock Trees
report_drc -file "$rpt_dir/drc.rpt"
report_clock_utilization -file "$rpt_dir/clock_utilization.rpt"
report_high_fanout_nets -max_nets 20 -file "$rpt_dir/high_fanout_nets.rpt"

# E. Multi-frequency Timing & Power Sweep (50 MHz to 200 MHz)
set freqs {50 75 100 125 150 180 200}
foreach f $freqs {
    set period [format "%.3f" [expr {1000.0 / $f}]]
    create_clock -period $period -name clk [get_ports clk]
    report_timing_summary -delay_type min_max -max_paths 1 -file "$rpt_dir/timing_${f}mhz.rpt"
    report_power -file "$rpt_dir/power_${f}mhz.rpt"
}

puts "\n================================================================================"
puts "   VIVADO FULL PHYSICAL BENCHMARK & SIGN-OFF COMPLETED SUCCESSFULLY!"
puts "   Reports written to: $rpt_dir"
puts "================================================================================"
exit
