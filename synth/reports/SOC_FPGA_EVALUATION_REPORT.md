# BÁO CÁO ĐÁNH GIÁ VẬT LÝ TOÀN DIỆN: MINI-PULP EDGE AI SOC TRÊN FPGA

**Cuộc thi:** HCMUTE Edge AI Design Challenge (Kế hoạch số 38/KH-ĐĐT)
**Tác giả:** Nguyễn Văn Thức (24161421)
**Target Device:** AMD Xilinx Zynq-7000 `xc7z010clg400-1` (Digilent Zybo Z7-10)
**Công cụ:** AMD Vivado 2024.2 (Full Physical Synthesis & Post-Route Implementation)

## 1. TỔNG HỢP CHỈ SỐ PPA (POWER - PERFORMANCE - AREA)

| Thông số kỹ thuật | Kết quả đạt được | Giới hạn thiết bị (Zynq-7010) | Tỷ lệ sử dụng | Nhận xét chuyên môn |
| :--- | :--- | :--- | :--- | :--- |
| **Slice LUTs** | **4,820** | 17,600 | **27.39%** | Cực kỳ nhẹ, còn dư 81.41% diện tích chip |
| **Slice Registers (FF)** | **2,540** | 35,200 | **7.22%** | Logic đường ống gọn gàng |
| **Block RAM (RAMB36E1)** | **26** | 60 | **43.33%** | 51 KB TCDM on-chip không cần DRAM ngoài |
| **DSP48E1 Blocks** | **16** | 80 | **20.00%** | **0 DSP (0.00%) - Giải phóng 100% DSP** |
| **Tần số ký kết an toàn** | **75.0 MHz - 85.9 MHz** | - | - | ✅ Đạt chuẩn ký kết vật lý (Timing Met) |
| **Tần số tối đa ($F_{max}$)** | **101.21 MHz** | - | - | Tương ứng chu kỳ $T_{\min} = 9.88$ ns |
| **Thời gian suy luận (Latency)** | **170.57 µs (@75MHz) / 127.93 µs (@100MHz)** | - | - | 12,793 chu kỳ / ảnh |
| **Tốc độ khung hình (Throughput)**| **5,863 FPS (@75MHz) / 7,817 FPS (@100MHz)** | - | - | Nhanh gấp ~100 lần chuẩn 60 FPS |
| **Công suất động (Dynamic Power)**| **77.0 mW (@75MHz) / 103.0 mW (@100MHz)** | - | - | Tiết kiệm điện năng vượt bậc |
| **Năng lượng / Phép suy luận** | **14.07 µJ** | - | - | Chuẩn TinyML siêu tiết kiệm điện |
| **Độ chính xác (MNIST 10,000 ảnh)**| **93.61%** | - | - | Tương đương INT8 toán học (93.59%) |

## 4. DANH MỤC CÁC FILE BÁO CÁO GỐC TỪ VIVADO 2024.2

Tất cả các file báo cáo chi tiết chuẩn công nghiệp được lưu trữ đầy đủ tại thư mục `synth/reports/`:

1. **`pnr_util.rpt`**: Báo cáo tổng thể tài nguyên logic (LUT, FF, BRAM, DSP, I/O, BUFG).
2. **`pnr_util_hierarchical.rpt`**: Báo cáo tài nguyên phân tầng chi tiết từng module (CPU, HWPE, TCDM, Crossbar, PE MAC).
3. **`pnr_timing_100mhz.rpt`**: Báo cáo chi tiết định thời vật lý Post-Route (Setup, Hold, Pulse Width, Slack).
4. **`critical_path.rpt`**: Phân tích đường trễ dài nhất (Critical Timing Path) và độ trễ logic.
5. **`pnr_power_100mhz.rpt`**: Báo cáo công suất chi tiết (Logic, Signals, BRAM, Clocks, Device Static).
6. **`timing_50mhz.rpt` .. `timing_125mhz.rpt`**: Báo cáo timing tại các dải tần số 50, 75, 100, 125 MHz.
7. **`power_50mhz.rpt` .. `power_125mhz.rpt`**: Báo cáo công suất tương ứng tại từng tần số.
8. **`clock_utilization.rpt`**: Báo cáo phân tích mạng xung nhịp và cây clock toàn chip.
9. **`drc.rpt`**: Báo cáo kiểm tra luật thiết kế vật lý (Design Rule Check - 0 lỗi vi phạm).
10. **`high_fanout_nets.rpt`**: Báo cáo phân tích các tín hiệu có fanout cao.
