# Mini-PULP Edge AI SoC: Zero-DSP Logarithmic Hardware Accelerator
**Author:** Nguyen Van Thuc (Student ID: 24161421)  
**Affiliation:** Faculty of Electrical and Electronics Engineering, HCMUTE  
**Competition Target:** HCMUTE Edge AI Design Challenge (Kế hoạch số 38/KH-ĐĐT)  
**Target Hardware:** Digilent Zybo Z7 (AMD Xilinx Zynq-7000 `xc7z010clg400-1`)  
**Application:** Real-Time Handwritten Digit Recognition (MNIST 28x28)  
**Languages:** SystemVerilog (IEEE 1800-2012), C (RISC-V Firmware), Python 3  
**EDA Toolchain:** AMD Vivado 2024.2 (Physical Implementation & Static Timing Sign-off)

---

## 1. Giới Thiệu Dự Án & Định Hướng Kiến Trúc

Dự án nghiên cứu, thiết kế và hiện thực hóa một hệ thống vi mạch hoàn chỉnh trên chip (**Edge AI System-on-Chip**) chuyên dụng cho các thiết bị biên hạn chế tài nguyên:
* **Host Control Plane:** Lõi vi điều khiển 32-bit RISC-V RV32I (`riscv_core_rv32i.sv`) siêu nhẹ tối ưu chốt giải mã, điều phối nạp dữ liệu, cấu hình qua thanh ghi CSR và truyền thông tin qua UART 115,200 Baud.
* **Data Plane (Bộ tăng tốc tự trị LA-HWPE):** Lấy cảm hứng từ hệ sinh thái **PULP (Parallel Ultra-Low-Power)** của ETH Zurich, tích hợp:
  * Hệ thống bộ nhớ trên chip đa ngân hàng **TCDM 34.6 KB** (`tcdm_weight_bram.sv`, `tcdm_activation_mem.sv`, `tcdm_bias_mem.sv`).
  * Mảng tính toán **1x4 SIMD Engine Output-Stationary** (`compute_engine_1x4.sv`).
  * **Lõi số học logarit tách kênh Zero-DSP:** Thay thế hoàn toàn các khối nhân phần cứng DSP48E1 bằng mạch cộng dịch logarit trong miền log nhị phân Mitchell cải tiến.
  * **Chuẩn nén trọng số Log8 8-bit trên bus 32-bit:** Thu gọn bề rộng bus từ 48-bit xuống đúng 32-bit chuẩn SoC, cắt giảm 10 khối BRAM36 (-41.7% dung lượng BRAM).
  * Vi kiến trúc PE MAC đường ống 2 tầng sâu cân bằng tải, đạt chuẩn ký kết vật lý an toàn **100.0 MHz** ($F_{\max} = 116.39\text{ MHz}$).
  * Bộ điều khiển luồng tự trị **AGU** (`hwpe_stream_ctrl.sv`) chạy pipeline không bóng bóng trễ (Zero-Bubble BRAM streaming).
  * Khối lượng tử hóa ngược tích hợp **Fused Requant-ReLU** và bộ tìm nhãn cực đại song song cây nhị phân **Argmax Classifier** (`argmax_unit.sv`).
* **Phần mềm tiền xử lý & Trình diễn (Application Layer):** Thuật toán căn tâm khối lượng 4 bước (Center-of-Mass) và bộ giao diện Live Demo Web GUI trực quan thời gian thực.

---

## 2. Cấu Trúc Nhánh & Quản Lý Phiên Bản Git (Git Industrial Standard)

Dự án được tổ chức theo chuẩn công nghiệp với các nhánh chuyên biệt (branches) và thẻ phát hành (release tags) tương ứng từng mốc tiến hóa kiến trúc:

### A. Sơ Đồ Nhánh (Branch Roadmap)
```
* master / release/v0.3.0-proposed (Final Production: Log8 32b, 16 BRAM, 0 DSP, 100MHz, Report)
|
|-- feature/center-of-mass-gui     (Tích hợp tiền xử lý COM 4 bước & Live Demo Web GUI)
|-- feature/timing-pipeline-100mhz (Đường ống hóa PE MAC 2 tầng & ký kết vật lý 100 MHz)
|-- baseline/v3-minipulp-v0.1.0    (Phiên bản Log12 48-bit bus, 26 BRAMs, 75 MHz)
|-- baseline/v2-hwpe-exact-int8    (Phiên bản phần cứng tăng tốc nhân chuẩn INT8, 16 DSPs)
`-- baseline/v1-software-golden    (Phiên bản phần mềm CPU RV32I thuần, không bộ tăng tốc)
```

### B. Danh Mục Thẻ Phiên Bản (Semantic Release Tags)

| Git Tag | Nhánh / Commit | Tên Phiên Bản | Đặc Điểm Kỹ Thuật Chính |
| :---: | :---: | :--- | :--- |
| **`v0.0.0`** | `baseline/v1-software-golden` | Initial RTL SoC Baseline | SoC RV32I ban đầu với mảng tính toán thô, chưa có bộ tăng tốc chuyên dụng. |
| **`v0.0.1`** | `baseline/v2-hwpe-exact-int8` | HWPE Prototype Engine | Tích hợp bộ tăng tốc phần cứng ban đầu với mạch nhân chuẩn INT8 (16 khối DSP). |
| **`v0.1.0`** | `baseline/v3-minipulp-v0.1.0` | Mini-PULP v0.1.0 (Log12) | Mảng 1x4 PE SIMD số học logarit 12-bit, bus 48-bit, 26 BRAM36, Web GUI, Makefile. |
| **`v0.1.1`** | `master` | Automated Demo Runner | Bổ sung script chạy demo 1-click `run_demo.sh` và cơ chế giải phóng cổng tự động. |
| **`v0.1.2`** | `master` | Vivado Sign-off Suite | Bộ công cụ trích xuất báo cáo PnR và quét tần số tự động (50 MHz đến 200 MHz). |
| **`v0.2.0`** | `feature/timing-pipeline-100mhz`| 100 MHz Timing Sign-off | Đường ống hóa PE MAC 2 tầng + CPU decode latching; WNS = +1.408 ns @ 100 MHz. |
| **`v0.2.1`** | `feature/center-of-mass-gui` | COM Preprocessing Engine | Tích hợp thuật toán tiền xử lý Bounding-Box và Căn tâm khối lượng vào Web GUI. |
| **`v0.3.0`** | `master` | Log8 32-bit Bus Engine | Chuẩn nén trọng số Log8 8-bit trên bus 32-bit, cắt giảm 10 BRAM36 (-41.7%), 0 DSP. |
| **`v0.3.1`** | `master` (HEAD) | **Final Industrial Release** | Đồng bộ hóa toàn bộ báo cáo khoa học IEEE 10 trang, bảng Ablation Study và gói Overleaf. |

---

## 3. Khảo Sát Đánh Đổi Kiến Trúc Thực Nghiệm (Ablation Study)

Toàn bộ thông số đều được đo đạc thực tế từ quá trình tổng hợp và Place & Route (PnR) trên cùng chip **AMD Xilinx Zynq-7000 (`xc7z010-1`)** và cùng thực thi tập kiểm thử **10,000 ảnh chuẩn MNIST**:

| Chỉ Số Đánh Giá PPA | Cấu Hình 1: Host RV32I CPU Thuần (Software Baseline) | Cấu Hình 2: Phần Cứng Exact INT8 MAC (DSP Baseline) | Cấu Hình 3: Bộ Tăng Tốc Log12 Sơ Khai (Mini-PULP v0.1.0) | Cấu Hình 4: Nghiên Cứu Đề Xuất (**Mini-PULP SoC v0.3.0**) |
| :--- | :---: | :---: | :---: | :---: |
| **Kiến trúc xử lý** | 1x Lõi RISC-V RV32I thuần | 1x RV32I + HWPE INT8 MAC | 1x RV32I + HWPE Log12 | **1x RV32I + LA-HWPE Log8 SIMD** |
| **Phương pháp số học** | Phần mềm C (Emulated MAC) | Nhân số học chính xác INT8 | Số học Logarit 12-bit sơ khai | **Số học Logarit Tách Kênh (Zero-DSP Log8)** |
| **Khối nhân DSP48E1** | 0 DSP (0.00%) | **16 khối DSP ($20.00\%$)** | 0 DSP (0.00%) | **0 DSP (0.00% -- GIẢI PHÓNG 100% DSP)** |
| **Tài nguyên Logic (LUTs)** | 1,610 LUTs (Chỉ riêng CPU) | 4,820 LUTs (CPU + HWPE) | 3,272 LUTs (CPU + HWPE) | **2,958 LUTs (Toàn bộ SoC cả CPU + HWPE)** |
| **Bộ nhớ BRAM on-chip** | 2 khối BRAM36 (8.0 KB mã lệnh) | 26 khối BRAM36 (51.0 KB) | 26 khối BRAM36 (51.0 KB) | **16 khối BRAM36 (34.6 KB -- Tiết kiệm 41.7%)** |
| **Xung nhịp ký kết ($F_{\text{clk}}$)**| 100.0 MHz | 85.0 MHz (Giới hạn DSP) | 75.0 MHz (Pipeline 1 tầng) | **100.0 MHz (Ký kết an toàn, WNS = +1.408 ns)** |
| **Tần số tối đa ($F_{\max}$)** | 116.39 MHz | 92.5 MHz | 86.0 MHz | **116.39 MHz (Tiềm năng PE MAC đạt >180 MHz)** |
| **Số chu kỳ xung nhịp / ảnh**| $\sim 508,160$ chu kỳ | 15,480 chu kỳ | 12,796 chu kỳ | **12,796 chu kỳ (Zero-Bubble Streaming)** |
| **Thời gian suy luận (Latency)**| 5,081.6 $\mu$s (5.08 ms) | 182.1 $\mu$s (@85MHz) | 170.61 $\mu$s (@75MHz) | **127.96 $\mu$s (@100MHz -- Nhanh hơn 39.7 lần)** |
| **Thông lượng (Throughput)** | 196 FPS | 5,490 FPS | 5,861 FPS | **7,815 FPS (Gấp 130 lần chuẩn video 60 FPS)** |
| **Công suất động ($P_{\text{dyn}}$)**| 32.0 mW (Chỉ CPU) | 145.0 mW (Gồm DSP + BRAM) | 77.0 mW | **65.0 mW (Tiết kiệm 55.2% so với INT8)** |
| **Năng lượng / Lượt suy luận**| 162.6 $\mu$J / ảnh | 26.39 $\mu$J / ảnh | 14.07 $\mu$J / ảnh | **8.32 $\mu$J / ảnh (Tiết kiệm 94.9% vs CPU, 68.4% vs INT8)** |
| **Độ chính xác MNIST (10k)** | 93.59% (INT8 math) | 93.59% (INT8 math) | 93.61% (Log12) | **93.88% (Test model) / 96.53% (Bit-exact)** |

---

## 4. Hướng Dẫn Vận Hành Hệ Thống (Makefile Command Interface)

Hệ thống cung cấp giao diện tự động hóa toàn diện qua `Makefile`:

```bash
make help        # Xem hướng dẫn tất cả các lệnh khả dụng
make sim         # Biên dịch và chạy mô phỏng toàn bộ SoC (tb_pulp_riscv_ai_soc)
make benchmark   # Kiểm thử phần cứng HWPE trên 10 chữ số (0..9) từ tập MNIST
make train       # Huấn luyện mô hình, lượng tử hóa INT8 và xuất file hex pre-encoded
make synth       # Chạy Vivado tổng hợp luận lý và Place & Route vật lý trên Zynq-7010
make report      # Xem bảng dashboard tổng kết chỉ số PPA (LUT, BRAM, DSP, FPS, Power)
make gui         # Khởi chạy giao diện Live Demo tương tác trực quan trên trình duyệt (port 8080)
make clean       # Dọn dẹp logs, build artifacts và waveform tạm
```

---

## 5. Cấu Trúc Thư Mục Dự Án (Directory Structure)

```
pulp_edge_ai_soc/
├── Makefile                       # Tự động hóa toàn bộ luồng EDA, Sim, Train, Report, GUI
├── README.md                      # Tài liệu tổng quan kiến trúc, PPA và hướng dẫn vận hành
├── .gitignore                     # Bộ lọc chuẩn công nghiệp loại bỏ build artifacts
├── rtl/                           # Toàn bộ mã nguồn SystemVerilog (SoC, HWPE, CPU, Memory)
│   ├── controller/                # FSM điều khiển luồng AGU, Requant-ReLU, Argmax
│   ├── core/                      # Mảng tính toán 1x4 PE MAC, Log-Antilog, LUTALM Zero-DSP
│   ├── memory/                    # Bộ nhớ trên chip TCDM (Weight, Activation, Bias)
│   ├── pkg/                       # Định nghĩa hằng số và cấu trúc giao tiếp gói tin
│   ├── soc/                       # Lõi CPU RISC-V RV32I, Interconnect CSR, UART Tx 115k
│   └── top/                       # Tầng kết nối top-level pulp_hwpe_top
├── sim/                           # Bộ kịch bản và testbench mô phỏng chu kỳ chính xác
├── sw/                            # Phần mềm nhúng, huấn luyện AI và giao diện người dùng
│   ├── data/                      # Trọng số tiền mã hóa, tệp bias hex và tập dữ liệu MNIST
│   ├── firmware/                  # Mã máy khởi động Boot ROM cho lõi RISC-V RV32I
│   ├── gui/                       # Giao diện Web GUI Live Demo trực quan thời gian thực
│   ├── parse_summary.py           # Bộ parser tự động trích xuất chỉ số PPA từ báo cáo Vivado
│   └── train_export.py            # Huấn luyện mô hình, lượng tử hóa và xuất ma trận trọng số
├── synth/                         # Kịch bản Vivado TCL và ràng buộc vật lý
│   ├── constrs.xdc                # Ràng buộc định thời chân chip và chu kỳ xung nhịp 100 MHz
│   ├── run_synth.tcl              # Kịch bản chạy tổng hợp và Post-Route Implementation
│   └── reports/                   # 27 tệp báo cáo PPA vật lý ký kết chính thức từ Vivado 2024.2
└── report/                        # Toàn bộ gói báo cáo khoa học IEEE hoàn chỉnh
    ├── IEEEtran.cls               # Định dạng chuẩn hội nghị IEEE
    ├── figures/                   # 13 sơ đồ kiến trúc vector PDF và ảnh chụp màn hình thực tế
    ├── report_pulp_edge_ai_soc.tex# Mã nguồn LaTeX bài báo khoa học 10 trang
    └── report_pulp_edge_ai_soc.pdf# Bản in PDF báo cáo chuẩn xuất bản chất lượng cao
```
