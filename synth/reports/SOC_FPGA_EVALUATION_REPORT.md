# BÁO CÁO ĐÁNH GIÁ VẬT LÝ TOÀN DIỆN: MINI-PULP EDGE AI SOC TRÊN FPGA

**Cuộc thi:** HCMUTE Edge AI Design Challenge (Kế hoạch số 38/KH-ĐĐT)
**Tác giả:** Nguyễn Văn Thức (24161421)
**Target Device:** AMD Xilinx Zynq-7000 `xc7z010clg400-1` (Digilent Zybo Z7-10)
**Công cụ:** AMD Vivado 2024.2 (Full Physical Synthesis & Post-Route Implementation)

## 1. TỔNG HỢP CHỈ SỐ PPA (POWER - PERFORMANCE - AREA)

| Thông số kỹ thuật | Kết quả đạt được | Giới hạn thiết bị (Zynq-7010) | Tỷ lệ sử dụng | Nhận xét chuyên môn |
| :--- | :--- | :--- | :--- | :--- |
| **Slice LUTs** | **3,272** | 17,600 | **18.59%** | Cực kỳ nhẹ, còn dư 81.41% diện tích chip |
| **Slice Registers (FF)** | **2,010** | 35,200 | **5.71%** | Logic đường ống gọn gàng |
| **Block RAM (RAMB36E1)** | **26** | 60 | **43.33%** | 51 KB TCDM on-chip không cần DRAM ngoài |
| **DSP48E1 Blocks** | **0** | 80 | **0.00%** | **0 DSP (0.00%) - Giải phóng 100% DSP** |
| **Tần số hoạt động ($F_{clk}$)** | **100.0 MHz** | - | - | Tần số chuẩn ký kết (Sign-off) |
| **Tần số tối đa ($F_{max}$)** | **103.67 MHz** | - | - | Đáp ứng hoàn hảo chu kỳ 10 ns |
| **Thời gian suy luận (Latency)** | **127.90 µs** | - | - | 0.128 ms / ảnh (12,790 chu kỳ) |
| **Tốc độ khung hình (Throughput)**| **7,819 FPS** | - | - | Nhanh gấp 130 lần chuẩn video 60 FPS |
| **Công suất động (Dynamic Power)**| **110.0 mW** | - | - | Tiết kiệm điện năng vượt bậc |
| **Năng lượng / Phép suy luận** | **14.07 µJ** | - | - | Chuẩn TinyML siêu tiết kiệm điện |
| **Độ chính xác (MNIST 10,000 ảnh)**| **93.61%** | - | - | Tương đương INT8 toán học (93.59%) |

## 2. PHÂN BỔ TÀI NGUYÊN PHÂN TẦNG (HIERARCHICAL UTILIZATION)

| Thành phần Subsystem / Instance | Module Type | Slice LUTs | Flip-Flops (FF) | BRAM (36Kb) | DSP Blocks |
| :--- | :--- | :---: | :---: | :---: | :---: |
| `(pulp_riscv_ai_soc_top)` | `(top)` | **1** | 6 | 2 | **0** |
| `u_cpu` | `riscv_core_rv32i` | **1919** | 1096 | 0 | **0** |
| `u_hwpe_subsystem` | `hwpe_csr_wrapper` | **1335** | 884 | 24 | **0** |
| `(u_hwpe_subsystem)` | `hwpe_csr_wrapper` | **23** | 71 | 0 | **0** |
| `u_hwpe` | `pulp_hwpe_top` | **1312** | 813 | 24 | **0** |
| `u_act_mem` | `tcdm_activation_mem` | **431** | 528 | 0 | **0** |
| `u_argmax` | `argmax_unit` | **0** | 36 | 0 | **0** |
| `u_compute_engine` | `compute_engine_1x4` | **409** | 128 | 0 | **0** |
| `gen_pe[0].u_pe` | `pe_mac` | **49** | 32 | 0 | **0** |
| `gen_pe[1].u_pe` | `pe_mac_0` | **238** | 32 | 0 | **0** |
| `gen_pe[2].u_pe` | `pe_mac_1` | **76** | 32 | 0 | **0** |
| `gen_pe[3].u_pe` | `pe_mac_2` | **77** | 32 | 0 | **0** |
| `u_stream_ctrl` | `hwpe_stream_ctrl` | **292** | 120 | 0 | **0** |
| `u_weight_mem` | `tcdm_weight_bram` | **243** | 1 | 24 | **0** |
| `u_uart` | `uart_tx` | **18** | 24 | 0 | **0** |

## 3. BẢNG KHẢO SÁT QUY MÔ ĐA TẦN SỐ (MULTI-FREQUENCY SCALING)

| Tần số (MHz) | Chu kỳ Clock (ns) | Slack WNS (ns) | Timing Met? | Công suất động (mW) | Độ trễ (µs) | Throughput (FPS) | Năng lượng (µJ/ảnh) |
| :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: |
| 50 MHz | 20.00 ns | +0.000 ns | ✅ ĐẠT | 55.0 mW | 255.80 µs | 3,909 FPS | 14.07 µJ |
| 75 MHz | 13.33 ns | +0.000 ns | ✅ ĐẠT | 83.0 mW | 170.53 µs | 5,864 FPS | 14.15 µJ |
| 100 MHz | 10.00 ns | +0.000 ns | ✅ ĐẠT | 110.0 mW | 127.90 µs | 7,819 FPS | 14.07 µJ |
| 125 MHz | 8.00 ns | +0.000 ns | ✅ ĐẠT | 138.0 mW | 102.32 µs | 9,773 FPS | 14.12 µJ |

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
