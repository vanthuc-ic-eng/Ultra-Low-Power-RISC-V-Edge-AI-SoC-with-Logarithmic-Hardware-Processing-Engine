# ==============================================================================
# Makefile for Mini-PULP Edge AI SoC Project
# Author: Nguyen Van Thuc (24161421)
# ==============================================================================

SHELL := /bin/bash
PROJ_DIR := $(shell pwd)
SIM_DIR  := $(PROJ_DIR)/sim
SW_DIR   := $(PROJ_DIR)/sw
SYNTH_DIR := $(PROJ_DIR)/synth

.PHONY: all help sim benchmark train synth report gui clean

all: benchmark sim report

help:
	@echo "================================================================================"
	@echo "   MINI-PULP EDGE AI SOC: COMMAND INTERFACE (MAKEFILE)"
	@echo "================================================================================"
	@echo "  make sim        : Biên dịch và chạy mô phỏng toàn bộ SoC (tb_pulp_riscv_ai_soc)"
	@echo "  make benchmark  : Kiểm thử phần cứng bộ tăng tốc HWPE trên 10 chữ số (0..9)"
	@echo "  make train      : Huấn luyện MLP & xuất bộ nhớ weights/biases định dạng log 48-bit"
	@echo "  make synth      : Chạy Vivado tổng hợp & Place-and-Route vật lý trên Zynq-7010"
	@echo "  make report     : Hiển thị bảng tổng hợp chỉ số PPA (LUT, BRAM, DSP, FPS, Power)"
	@echo "  make gui        : Mở giao diện Web Live Demo trực quan tương tác vẽ số"
	@echo "  make clean      : Dọn dẹp logs, build artifacts và waveform tạm"
	@echo "================================================================================"

sim:
	@echo "==> [SIM] Compiling and running Full SoC Verification..."
	cd $(SIM_DIR) && iverilog -g2012 -o tb_soc.vvp \
		../rtl/pkg/pulp_hwpe_pkg.sv \
		../rtl/core/*.sv \
		../rtl/memory/*.sv \
		../rtl/controller/*.sv \
		../rtl/top/*.sv \
		../rtl/soc/*.sv \
		tb_pulp_riscv_ai_soc.sv
	cd $(SIM_DIR) && vvp tb_soc.vvp

benchmark:
	@echo "==> [BENCHMARK] Running 10-Digit Multi-Sample Hardware Benchmark..."
	cd $(SIM_DIR) && iverilog -g2012 -o tb_top_sv.vvp \
		../rtl/pkg/pulp_hwpe_pkg.sv \
		../rtl/core/*.sv \
		../rtl/memory/*.sv \
		../rtl/controller/*.sv \
		../rtl/top/*.sv \
		tb_pulp_hwpe_top.sv
	cd $(SIM_DIR) && vvp tb_top_sv.vvp

train:
	@echo "==> [TRAIN] Running INT8 quantization and pre-encoded weight export..."
	python3 $(SW_DIR)/train_export.py

synth:
	@echo "==> [SYNTH] Running Vivado batch synthesis and physical implementation..."
	cd $(SYNTH_DIR) && vivado -mode batch -source run_synth.tcl

report:
	@python3 $(SW_DIR)/report_summary.py

gui:
	@echo "==> [GUI] Starting Live Demo Interactive Server..."
	python3 $(SW_DIR)/gui/app.py

clean:
	@echo "==> [CLEAN] Cleaning simulation and build artifacts..."
	rm -f $(SIM_DIR)/*.vvp $(SIM_DIR)/*.vcd
	rm -f $(SYNTH_DIR)/*.jou $(SYNTH_DIR)/*.log $(SYNTH_DIR)/clockInfo.txt
	@echo "Clean completed."
