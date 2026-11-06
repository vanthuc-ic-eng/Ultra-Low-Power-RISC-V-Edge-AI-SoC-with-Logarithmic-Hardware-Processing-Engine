# ==============================================================================
# File: run_synth.tcl
# Project: PULP-inspired Edge AI SoC for Handwritten Digit Recognition
# Target Part: AMD Xilinx Zynq-7000 xc7z010clg400-1 (Digilent Zybo Z7-10)
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

# Synthesis (Out of context)
synth_design -top pulp_riscv_ai_soc_top -part xc7z010clg400-1 -mode out_of_context

# Implementation
opt_design
place_design
route_design

# Reports
report_utilization -file $rpt_dir/utilization.rpt
report_timing_summary -delay_type min_max -max_paths 10 -file $rpt_dir/timing.rpt
report_power -file $rpt_dir/power.rpt

puts "================================================================================"
puts "   VIVADO SYNTHESIS & IMPLEMENTATION COMPLETED SUCCESSFULLY!"
puts "================================================================================"
exit
