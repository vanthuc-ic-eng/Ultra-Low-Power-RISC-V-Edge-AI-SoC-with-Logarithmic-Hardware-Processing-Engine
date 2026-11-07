# Mini-PULP Edge AI SoC: Version v0-baseline
**Branch:** `v0-baseline` (Initial Unoptimized State & Software Baseline)  
**Target Hardware:** Digilent Zybo Z7 (AMD Xilinx Zynq-7000 `xc7z010clg400-1`)  
**Characteristics of this Initial State:**
* **Unoptimized PE Architecture:** Each PE element instantiates independent Log Encoders for both weights and activations (redundant logic).
* **Unpipelined Datapath:** Long 20-level combinatorial paths causing **Timing Failure at 100 MHz (WNS = -5.000 ns)**.
* **Pure Software Execution Mode:** Lõi RISC-V RV32I thực thi mạng nơ-ron thuần bằng phần mềm C mất ~508,160 chu kỳ (~5.08 ms, 196 FPS, $162.6\,\mu\text{J}$).
* **Resource Profile:** 3,264 Slice LUTs, 1,979 FFs, 18 BRAM36 blocks, 0 DSPs.

---

## 1. Kết Quả Thực Nghiệm PPA Riêng Biệt Cho Nhánh v0 (Isolated Sign-off Reports)

Trích xuất trực tiếp từ báo cáo PnR vật lý Vivado 2024.2 trong thư mục [`synth/reports/`](synth/reports/):

| Chỉ số PPA | Kết quả đạt được | Giới hạn Zynq-7010 | Tỷ lệ sử dụng | Nhận xét chuyên môn |
| :--- | :---: | :---: | :---: | :--- |
| **Slice LUTs** | **3,264** | 17,600 | **18.55%** | Mảng PE mang encoder dư thừa |
| **Slice Registers (FF)** | **1,979** | 35,200 | **5.62%** | Chưa đường ống hóa |
| **Block RAM (RAMB36E1)** | **18** | 60 | **30.00%** | Chứa mã lệnh và dữ liệu ban đầu |
| **DSP48E1 Multipliers** | **0** | 80 | **0.00%** | Chưa tối ưu hóa |
| **Xung nhịp ràng buộc** | **100.0 MHz** | - | - | ❌ **TIMING FAILED: WNS = -5.000 ns** |
| **Tần số hoạt động thực tế** | **~50.0 MHz** | - | - | Giới hạn bởi 20 tầng logic |
| **Thời gian suy luận (CPU C)**| **5,081.60 µs (5.08 ms)**| - | - | ~508,160 chu kỳ clock thực thi phần mềm C |
| **Thông lượng xử lý (CPU FPS)**| **196 FPS** | - | - | Không đáp ứng yêu cầu xử lý thời gian thực |
| **Công suất động ($P_{\text{dyn}}$)**| **98.0 mW** | - | - | Tiêu hao chuyển mạch do logic tổ hợp sâu |
| **Năng lượng / Lượt suy luận**| **162.60 µJ / ảnh** | - | - | Tiêu hao năng lượng cao khi chạy phần mềm |
| **Độ chính xác MNIST (10k)** | **93.59%** | - | - | Khớp mô hình toán học lượng tử hóa |

---

## 2. Hướng Dẫn Vận Hành Đo Đạc (Common Benchmark Interface)

```bash
make report      # Chạy script đo đạc và in báo cáo PPA riêng biệt của nhánh v0
make benchmark   # Kiểm thử chu kỳ và độ chính xác phần cứng trên tập test
make sim         # Chạy mô phỏng RTL đầy đủ bằng Icarus Verilog
make gui         # Khởi chạy Live Demo Web GUI
```
