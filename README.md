# Mini-PULP Edge AI SoC: Zero-DSP Logarithmic Hardware Accelerator
**Author:** Nguyen Van Thuc (Student ID: 24161421)  
**Target Hardware:** Digilent Zybo Z7 (AMD Xilinx Zynq-7000 `xc7z010clg400-1`)  
**Application:** Real-Time Handwritten Digit Recognition (MNIST 28x28)  
**Language:** SystemVerilog (IEEE 1800-2012) & Python 3

---

## 1. Giới Thiệu Dự Án & Định Hướng Kiến Trúc

Dự án phát triển một hệ thống vi mạch hoàn chỉnh trên chip (**Edge AI System-on-Chip**) chuyên dụng cho các thiết bị biên hạn chế tài nguyên:
* **Host Control Plane:** Lõi vi điều khiển 32-bit RISC-V RV32I (`riscv_core_rv32i.sv`) siêu nhẹ, điều phối nạp dữ liệu, khởi động bộ tăng tốc qua thanh ghi CSR và truyền thông tin qua UART.
* **Data Plane (Bộ tăng tốc tự trị LA-HWPE):** Lấy cảm hứng từ hệ sinh thái **PULP (Parallel Ultra-Low-Power)** của ETH Zurich, tích hợp:
  * Hệ thống bộ nhớ trên chip đa ngân hàng **TCDM 51 KB** (`tcdm_weight_bram.sv`, `tcdm_activation_mem.sv`, `tcdm_bias_mem.sv`).
  * Mảng tính toán **1x4 SIMD Engine Output-Stationary** (`compute_engine_1x4.sv`).
  * **Lõi nhân độc quyền:** Tái sử dụng mạch nhân xấp xỉ logarit đạt chuẩn PPA cực hạn (**Zero-DSP LUT-ALM**) từ dự án nghiên cứu số học `mult_8bit`.
  * Bộ điều khiển luồng tự trị **AGU** (`hwpe_stream_ctrl.sv`) chạy pipeline không bóng bóng trễ (Zero-Bubble BRAM streaming).
  * Khối lượng tử hóa ngược tích hợp **Fused Requant-ReLU** và bộ tìm nhãn cực đại phần cứng **Argmax Classifier** (`argmax_unit.sv`).

---

## 2. Quản Lý Phiên Bản Git (Git Versioning & Release Tags)

Dự án được gắn thẻ (release tags) rõ ràng để minh chứng tiến hóa kiến trúc:

| Git Tag | Mô Tả Phiên Bản | Đặc Điểm Kỹ Thuật |
| :---: | :--- | :--- |
| **`v0.0.0`** | **Baseline Mini-PULP SoC** | SoC ban đầu với mảng 1x4 PE tích hợp mạch nhân `lutalm_mul_s8` đầy đủ (mỗi PE tự chạy encoder cho cả activation và weight). |
| **`v0.1.0`** | **LA-HWPE V2 Extreme SIMD Core** | • **Pre-encoded Log-Weights:** Trọng số được tính sẵn ở miền logarit trong BRAM 48-bit (xóa bỏ 4 bộ encoder trong PE).<br>• **Shared Activation Encoder:** Điểm ảnh được mã hóa logarit 1 lần duy nhất rồi broadcast cho cả 4 PE.<br>• **Lõi PE Siêu Nhẹ:** Chỉ còn bộ cộng 9-bit + Antilog + Accumulator 32-bit.<br>• **Timing Fix:** Ngắt đường trễ 20 tầng logic trong CPU RV32I. |

---

## 3. Hướng Dẫn Vận Hành Hệ Thống (Makefile Command Interface)

Hệ thống cung cấp giao diện dòng lệnh ngắn gọn, tự động hóa toàn bộ qua `Makefile`:

```bash
make help        # Xem hướng dẫn tất cả các lệnh khả dụng
make sim         # Biên dịch và chạy mô phỏng toàn bộ SoC (tb_pulp_riscv_ai_soc)
make benchmark   # Kiểm thử phần cứng HWPE trên 10 chữ số (0..9) từ tập MNIST
make train       # Huấn luyện mô hình, lượng tử hóa INT8 và xuất file hex pre-encoded
make synth       # Chạy Vivado tổng hợp luận lý và Place & Route vật lý trên Zynq-7010
make report      # Xem bảng dashboard tổng kết chỉ số PPA (LUT, BRAM, DSP, FPS, Power)
make gui         # Khởi chạy giao diện Live Demo tương tác trực quan trên trình duyệt
make clean       # Dọn dẹp logs, build artifacts và waveform tạm
```

---

## 4. Giao Diện Demo Trực Quan (Live Interactive Web GUI)

Để phục vụ trình diễn trực tiếp tại bàn chấm thi của Ban Giám Khảo:
```bash
make gui
```
Hệ thống sẽ mở giao diện Web tại `http://localhost:8080/`:
* **Bảng vẽ cảm ứng / chuột (Canvas 28x28):** Cho phép giám khảo tự tay vẽ chữ số bất kỳ.
* **1-Click Test Samples:** Nạp nhanh 10 mẫu chữ số chuẩn (0 đến 9) từ tập kiểm thử MNIST.
* **Bảng đồng hồ vi mạch thời gian thực (Hardware Telemetry):**
  * Tốc độ suy luận: **$127.90\ \mu\text{s}$** ($7,819\text{ FPS}$).
  * Số chu kỳ clock: **$12,790\text{ cycles}$**.
  * Năng lượng tiêu thụ: **$14.07\ \mu\text{J / inference}$**.
  * Công suất động: **$110\text{ mW}$** (Tổng công suất $203\text{ mW}$).
  * Khối cứng DSP: **$0 / 80\ (0.00\%)$**.
* **Chế độ chạy linh hoạt:**
  * `Mô phỏng Phần cứng Bit-Exact RTL`: Chạy trực tiếp qua mô hình giải tích phần cứng chính xác $100\%$ không cần cắm board.
  * `Board Thật FPGA (UART / USB)`: Gửi trực tiếp 784 bytes qua cáp micro-USB (`/dev/ttyUSB*`) xuống board Digilent Zybo Z7 để board thực thi và trả kết quả.

---

## 5. Thống Kê PPA Thực Tế Trên FPGA (AMD Xilinx Zynq-7000 `xc7z010`)

| Chỉ số PPA | Giá trị thực tế | Tỷ lệ sử dụng | Đánh giá |
| :--- | :---: | :---: | :--- |
| **Slice LUTs** | **3,272** | **18.59%** (3,272 / 17,600) | Cực kỳ gọn, dư 81.4% diện tích chip |
| **Slice Registers** | **2,010** | **5.71%** (2,010 / 35,200) | Rất thấp |
| **Block RAM (RAMB36E1)** | **26** | **43.33%** (26 / 60) | Chứa trọn 51 KB weights 48-bit |
| **Khối cứng DSP48E1** | **0** | **0.00%** (0 / 80) | **Zero-DSP tuyệt đối!** |
| **Xung nhịp hệ thống** | **100.0 MHz** | - | Chu kỳ 10.0 ns |
| **Thời gian suy luận** | **$127.90\ \mu\text{s}$** | - | $12,790$ chu kỳ clock |
| **Thông lượng xử lý** | **$7,819\text{ FPS}$** | - | Bỏ xa camera 30-60 FPS |
| **Công suất động** | **$110\text{ mW}$** | - | Siêu mát (Junction Temp 27.3 °C) |
| **Năng lượng / Lần đoán** | **$14.07\ \mu\text{J}$** | - | Đạt chuẩn thế giới về TinyML |
| **Độ chính xác (10k ảnh)** | **$93.61\% - 93.69\%$**| - | Độ lệch so với mạch chuẩn chỉ 0.04% |
