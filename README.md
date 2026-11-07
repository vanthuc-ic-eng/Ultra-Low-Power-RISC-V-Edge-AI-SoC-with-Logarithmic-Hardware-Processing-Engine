# Mini-PULP Edge AI SoC: Version v3-pipelined-100mhz
**Branch:** `v3-pipelined-100mhz` (Corresponds to Semantic Release Tag `v0.2.0` / `v0.2.1`)  
**Target Hardware:** Digilent Zybo Z7 (AMD Xilinx Zynq-7000 `xc7z010clg400-1`)  
**Key Innovations in this Branch:**
* **2-Stage Pipelined PE MAC:** Inserted pipeline registers between the logarithmic multiplier and the 32-bit accumulator.
* **Decode-Latched CPU RV32I:** Latched `rs1_data_q` and `rs2_data_q` in `STATE_DECODE`, breaking the 20-level combinatorial critical path.
* **Physical Timing Sign-off @ 100.0 MHz:** WNS = **+1.408 ns** (Zero violations), $F_{\max} = \mathbf{116.39\text{ MHz}}$.
* **Center-of-Mass (COM) Preprocessing & Live Demo Web GUI:** Real-time handwritten digit recognition canvas with 4-stage bounding box & COM centering.
* **Memory Architecture:** 48-bit bus, **26 Block RAMs (RAMB36E1)** (51.0 KB on-chip TCDM).

---

## 1. Kết Quả Thực Nghiệm PPA Riêng Biệt Cho Nhánh v3 (Isolated Sign-off Reports)

Trích xuất trực tiếp từ báo cáo PnR vật lý Vivado 2024.2 trong thư mục [`synth/reports/`](synth/reports/):

| Chỉ số PPA | Kết quả đạt được | Giới hạn Zynq-7010 | Tỷ lệ sử dụng | Nhận xét chuyên môn |
| :--- | :---: | :---: | :---: | :--- |
| **Slice LUTs** | **2,980** | 17,600 | **16.93%** | Tiết kiệm diện tích logic |
| **Slice Registers (FF)** | **2,280** | 35,200 | **6.48%** | Cân bằng tải đường ống cao |
| **Block RAM (RAMB36E1)** | **26** | 60 | **43.33%** | 51.0 KB TCDM on-chip (bus 48-bit) |
| **DSP48E1 Multipliers** | **0** | 80 | **0.00%** | **ZERO-DSP (100% tài nguyên DSP tự do)** |
| **Xung nhịp ký kết an toàn** | **100.0 MHz** | - | - | ✅ **Timing Met: WNS = +1.408 ns (0 lỗi)** |
| **Tần số hoạt động tối đa ($F_{\max}$)**| **116.39 MHz**| - | - | Giới hạn bởi đường ghi thanh ghi CPU |
| **Thời gian suy luận (Latency)**| **127.96 µs** | - | - | 12,796 chu kỳ clock @ 100 MHz |
| **Thông lượng xử lý (FPS)** | **7,815 FPS** | - | - | Vượt xa chuẩn camera thời gian thực |
| **Công suất động ($P_{\text{dyn}}$)**| **65.0 mW** | - | - | Nhiệt độ tiếp giáp bán dẫn chỉ 26.8°C |
| **Năng lượng / Lượt suy luận**| **8.32 µJ / ảnh** | - | - | **Chuẩn Ultra-Low-Power TinyML** |
| **Độ chính xác MNIST (10k)** | **93.88%** | - | - | Vượt mô hình INT8 chuẩn (+0.29%) |

---

## 2. Hướng Dẫn Vận Hành Đo Đạc (Common Benchmark Interface)

```bash
make report      # Chạy script đo đạc và in báo cáo PPA riêng biệt của nhánh v3
make benchmark   # Kiểm thử chu kỳ và độ chính xác phần cứng trên tập test
make sim         # Chạy mô phỏng RTL đầy đủ bằng Icarus Verilog
make gui         # Khởi chạy Live Demo Web GUI có tích hợp tiền xử lý COM
```
