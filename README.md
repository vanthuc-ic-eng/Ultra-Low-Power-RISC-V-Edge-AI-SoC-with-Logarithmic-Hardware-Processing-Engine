# Mini-PULP Edge AI SoC: Version v1-exact-int8
**Branch:** `v1-exact-int8` (Traditional Baseline Hardware Accelerator)  
**Target Hardware:** Digilent Zybo Z7 (AMD Xilinx Zynq-7000 `xc7z010clg400-1`)  
**Key Architectural Characteristics of this Branch:**
* **Arithmetic Method:** Standard Exact INT8 Multiply-Accumulate (MAC) mapped directly to hardware DSP48E1 slices.
* **DSP Consumption:** **16 DSP48E1 Blocks ($20.00\%$)** used for 4 parallel MAC units.
* **On-Chip Memory:** 26 Block RAMs (RAMB36E1) (51.0 KB on-chip TCDM weight, activation, and bias memory).
* **Logic Utilization:** 4,820 Slice LUTs (gồm cả lõi CPU RV32I và mảng MAC phần cứng).
* **Physical Timing:** Reaches physical timing closure at 85.0 MHz ($F_{\max} = 92.5\text{ MHz}$) due to DSP cascade routing delay.
* **Energy Profile:** Dynamic power $145.0\text{ mW}$, energy per inference $26.39\,\mu\text{J / image}$.

---

## 1. Kết Quả Thực Nghiệm PPA Riêng Biệt Cho Nhánh v1 (Isolated Sign-off Reports)

Trích xuất trực tiếp từ báo cáo PnR vật lý Vivado 2024.2 trong thư mục [`synth/reports/`](synth/reports/):

| Chỉ số PPA | Kết quả đạt được | Giới hạn Zynq-7010 | Tỷ lệ sử dụng | Nhận xét chuyên môn |
| :--- | :---: | :---: | :---: | :--- |
| **Slice LUTs** | **4,820** | 17,600 | **27.39%** | Mảng MAC chính xác chiếm nhiều diện tích |
| **Slice Registers (FF)** | **2,540** | 35,200 | **7.22%** | Tiêu thụ thanh ghi định tuyến mảng DSP |
| **Block RAM (RAMB36E1)** | **26** | 60 | **43.33%** | 51.0 KB TCDM on-chip (bus 48-bit truyền thống) |
| **DSP48E1 Multipliers** | **16** | 80 | **20.00%** | **Tiêu tốn 16 khối DSP chuyên dụng cho 4 MACs** |
| **Xung nhịp ký kết an toàn** | **85.0 MHz** | - | - | ✅ **Timing Met: WNS = +0.120 ns** |
| **Tần số hoạt động tối đa ($F_{\max}$)**| **92.5 MHz** | - | - | Bị giới hạn bởi trễ tổ hợp qua khối DSP |
| **Thời gian suy luận (Latency)**| **182.10 µs** | - | - | 15,480 chu kỳ clock @ 85 MHz |
| **Thông lượng xử lý (FPS)** | **5,490 FPS** | - | - | Nhanh hơn chạy CPU nhưng ngốn điện |
| **Công suất động ($P_{\text{dyn}}$)**| **145.0 mW** | - | - | Tiêu hao công suất lớn do 16 DSP chuyển mạch |
| **Năng lượng / Lượt suy luận**| **26.39 µJ / ảnh** | - | - | Gấp hơn 3 lần so với bản đề xuất Log8 |
| **Độ chính xác MNIST (10k)** | **93.59%** | - | - | Chuẩn toán học lượng tử hóa INT8 |

---

## 2. Hướng Dẫn Vận Hành Đo Đạc (Common Benchmark Interface)

```bash
make report      # Chạy script đo đạc và in báo cáo PPA riêng biệt của nhánh v1
make benchmark   # Kiểm thử chu kỳ và độ chính xác phần cứng trên tập test
make sim         # Chạy mô phỏng RTL đầy đủ bằng Icarus Verilog
make gui         # Khởi chạy Live Demo Web GUI
```
