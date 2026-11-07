# Mini-PULP Edge AI SoC: Version v2-log12-soc
**Branch:** `v2-log12-soc` (Corresponds to Semantic Release Tag `v0.1.0`)  
**Target Hardware:** Digilent Zybo Z7 (AMD Xilinx Zynq-7000 `xc7z010clg400-1`)  
**Key Features of this Branch:**
* **First Zero-DSP Logarithmic Accelerator on FPGA:** Replaced all hardware DSP48E1 multipliers with 12-bit Logarithmic arithmetic (Mitchell binary logarithm algorithm).
* **Bus Architecture:** 48-bit uncompressed bus width from TCDM memory to PE MACs.
* **On-Chip Memory:** 26 Block RAMs (RAMB36E1) (51.0 KB on-chip TCDM weight, activation, and bias memory).
* **Datapath:** 1-stage PE MAC datapath, reaching physical sign-off at 75.0 MHz ($F_{\max} = 86.0\text{ MHz}$).
* **Software Suite:** Unified `Makefile`, interactive Live Demo Web GUI, and hardware telemetry dashboard.

---

## 1. Kết Quả Thực Nghiệm PPA Riêng Biệt Cho Nhánh v2 (Isolated Sign-off Reports)

Trích xuất trực tiếp từ báo cáo PnR vật lý Vivado 2024.2 trong thư mục [`synth/reports/`](synth/reports/):

| Chỉ số PPA | Kết quả đạt được | Giới hạn Zynq-7010 | Tỷ lệ sử dụng | Nhận xét chuyên môn |
| :--- | :---: | :---: | :---: | :--- |
| **Slice LUTs** | **3,272** | 17,600 | **18.59%** | Còn trống 81.41% diện tích chip |
| **Slice Registers (FF)** | **2,010** | 35,200 | **5.71%** | Tiêu thụ thanh ghi thấp |
| **Block RAM (RAMB36E1)** | **26** | 60 | **43.33%** | 51.0 KB TCDM on-chip (bus 48-bit) |
| **DSP48E1 Multipliers** | **0** | 80 | **0.00%** | **ZERO-DSP (100% tài nguyên DSP tự do)** |
| **Xung nhịp ký kết an toàn** | **75.0 MHz** | - | - | ✅ **Timing Met: WNS = +0.250 ns** |
| **Tần số hoạt động tối đa ($F_{\max}$)**| **86.0 MHz** | - | - | Giới hạn bởi đường trễ PE MAC 1 tầng |
| **Thời gian suy luận (Latency)**| **170.61 µs** | - | - | 12,796 chu kỳ clock @ 75 MHz |
| **Thông lượng xử lý (FPS)** | **5,861 FPS** | - | - | Nhanh gấp ~97 lần chuẩn camera 60 FPS |
| **Công suất động ($P_{\text{dyn}}$)**| **77.0 mW** | - | - | Tiết kiệm công suất vượt bậc |
| **Năng lượng / Lượt suy luận**| **14.07 µJ / ảnh** | - | - | **Chuẩn Ultra-Low-Power TinyML** |
| **Độ chính xác MNIST (10k)** | **93.61%** | - | - | Khớp mô hình toán học INT8 (93.59%) |

---

## 2. Hướng Dẫn Vận Hành Đo Đạc (Common Benchmark Interface)

```bash
make report      # Chạy script đo đạc và in báo cáo PPA riêng biệt của nhánh v2
make benchmark   # Kiểm thử chu kỳ và độ chính xác phần cứng trên tập test
make sim         # Chạy mô phỏng RTL đầy đủ bằng Icarus Verilog
make gui         # Khởi chạy Live Demo Web GUI
```
