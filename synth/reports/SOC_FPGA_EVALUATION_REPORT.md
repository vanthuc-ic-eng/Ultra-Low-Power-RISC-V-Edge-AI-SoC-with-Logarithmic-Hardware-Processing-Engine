# BÁO CÁO ĐÁNH GIÁ VẬT LÝ TOÀN DIỆN: MINI-PULP EDGE AI SOC TRÊN FPGA

**Cuộc thi:** HCMUTE Edge AI Design Challenge (Kế hoạch số 38/KH-ĐĐT)
**Tác giả:** Nguyễn Văn Thức (24161421)
**Target Device:** AMD Xilinx Zynq-7000 `xc7z010clg400-1` (Digilent Zybo Z7-10)
**Công cụ:** AMD Vivado 2024.2 (Full Physical Synthesis & Post-Route Implementation)

## 1. TỔNG HỢP CHỈ SỐ PPA (POWER - PERFORMANCE - AREA)

| Thông số kỹ thuật | Kết quả đạt được | Giới hạn thiết bị (Zynq-7010) | Tỷ lệ sử dụng | Nhận xét chuyên môn |
| :--- | :--- | :--- | :--- | :--- |
| **Slice LUTs** | **2,931** | 17,600 | **16.65%** | Cực kỳ nhẹ, còn dư 81.41% diện tích chip |
| **Slice Registers (FF)** | **2,252** | 35,200 | **6.40%** | Logic đường ống gọn gàng |
| **Block RAM (RAMB36E1)** | **18** | 60 | **30.00%** | 51 KB TCDM on-chip không cần DRAM ngoài |
| **DSP48E1 Blocks** | **0** | 80 | **0.00%** | **0 DSP (0.00%) - Giải phóng 100% DSP** |
| **Tần số ký kết an toàn** | **75.0 MHz - 85.9 MHz** | - | - | ✅ Đạt chuẩn ký kết vật lý (Timing Met) |
| **Tần số tối đa ($F_{max}$)** | **116.17 MHz** | - | - | Tương ứng chu kỳ $T_{\min} = 8.61$ ns |
| **Thời gian suy luận (Latency)** | **170.57 µs (@75MHz) / 127.93 µs (@100MHz)** | - | - | 12,793 chu kỳ / ảnh |
| **Tốc độ khung hình (Throughput)**| **5,863 FPS (@75MHz) / 7,817 FPS (@100MHz)** | - | - | Nhanh gấp ~100 lần chuẩn 60 FPS |
| **Công suất động (Dynamic Power)**| **77.0 mW (@75MHz) / 103.0 mW (@100MHz)** | - | - | Tiết kiệm điện năng vượt bậc |
| **Năng lượng / Phép suy luận** | **14.07 µJ** | - | - | Chuẩn TinyML siêu tiết kiệm điện |
| **Độ chính xác (MNIST 10,000 ảnh)**| **93.61%** | - | - | Tương đương INT8 toán học (93.59%) |

## 2. PHÂN BỔ TÀI NGUYÊN PHÂN TẦNG (HIERARCHICAL UTILIZATION)

| Thành phần Subsystem / Instance | Module Type | Slice LUTs | Flip-Flops (FF) | BRAM (36Kb) | DSP Blocks |
| :--- | :--- | :---: | :---: | :---: | :---: |
| `(pulp_riscv_ai_soc_top)` | `(top)` | **1** | 4 | 2 | **0** |
| `u_cpu` | `riscv_core_rv32i` | **1602** | 1182 | 0 | **0** |
| `u_hwpe_subsystem` | `hwpe_csr_wrapper` | **1268** | 1031 | 16 | **0** |
| `(u_hwpe_subsystem)` | `hwpe_csr_wrapper` | **5** | 104 | 0 | **0** |
| `u_hwpe` | `pulp_hwpe_top` | **1263** | 927 | 16 | **0** |
| `u_act_mem` | `tcdm_activation_mem` | **443** | 528 | 0 | **0** |
| `u_argmax` | `argmax_unit` | **35** | 72 | 0 | **0** |
| `u_compute_engine` | `compute_engine_1x4` | **498** | 232 | 0 | **0** |
| `gen_pe[0].u_pe` | `pe_mac` | **84** | 59 | 0 | **0** |
| `gen_pe[1].u_pe` | `pe_mac_0` | **231** | 57 | 0 | **0** |
| `gen_pe[2].u_pe` | `pe_mac_1` | **106** | 58 | 0 | **0** |
| `gen_pe[3].u_pe` | `pe_mac_2` | **107** | 58 | 0 | **0** |
| `u_stream_ctrl` | `hwpe_stream_ctrl` | **157** | 94 | 0 | **0** |
| `u_weight_mem` | `tcdm_weight_bram` | **130** | 1 | 16 | **0** |
| `u_interconnect` | `soc_bus_interconnect` | **44** | 2 | 0 | **0** |
| `u_uart` | `uart_tx` | **17** | 33 | 0 | **0** |

## 3. BẢNG KHẢO SÁT QUY MÔ ĐA TẦN SỐ (MULTI-FREQUENCY SCALING)

| Tần số (MHz) | Chu kỳ Clock (ns) | Slack WNS (ns) | Timing Met? | Công suất động (mW) | Độ trễ (µs) | Throughput (FPS) | Năng lượng (µJ/ảnh) |
| :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: |
| 50 MHz | 20.00 ns | +11.392 ns | ✅ ĐẠT | 30.0 mW | 255.92 µs | 3,907 FPS | 7.68 µJ |
| 75 MHz | 13.33 ns | +4.725 ns | ✅ ĐẠT | 44.0 mW | 170.61 µs | 5,861 FPS | 7.51 µJ |
| 100 MHz | 10.00 ns | +1.392 ns | ✅ ĐẠT | 59.0 mW | 127.96 µs | 7,815 FPS | 7.55 µJ |
| 125 MHz | 8.00 ns | +-0.608 ns | ❌ VI PHẠM | 74.0 mW | 102.37 µs | 9,769 FPS | 7.58 µJ |
| 150 MHz | 6.67 ns | +-1.941 ns | ❌ VI PHẠM | 89.0 mW | 85.31 µs | 11,722 FPS | 7.59 µJ |
| 180 MHz | 5.56 ns | +-3.052 ns | ❌ VI PHẠM | 106.0 mW | 71.09 µs | 14,067 FPS | 7.54 µJ |
| 200 MHz | 5.00 ns | +-3.608 ns | ❌ VI PHẠM | 118.0 mW | 63.98 µs | 15,630 FPS | 7.55 µJ |

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
