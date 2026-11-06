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
| **`v0.2.0`** | **Pipelined Datapath & Physical Timing Sign-Off** | • **Pipelined PE MAC Datapath:** Chèn thanh ghi đường ống giữa bộ nhân logarit (`lutalm_core_mul_s8`) và bộ tích lũy 32-bit (`acc_o`). HWPE đạt tiềm năng $F_{max} > 180$ MHz.<br>• **2-Stage Binary Tree Argmax:** Tách khối tìm nhãn cực đại 4 ngõ vào song song thành đường ống 2 chu kỳ.<br>• **CPU Decode Register Latching:** Chốt thanh ghi `rs1_data_q` / `rs2_data_q` tại `STATE_DECODE`, cắt rời bộ dồn kênh 32:1 ra khỏi chu kỳ ALU.<br>• **Post-Route Timing Sign-Off:** Ký kết vật lý đạt chuẩn tại **100.0 MHz** (WNS = **+1.408 ns**, 0 lỗi vi phạm) trên Xilinx Zynq-7010, $F_{max}$ đạt **116.39 MHz**.<br>• **Công suất cực thấp:** 65.0 mW dynamic power, tiêu thụ chỉ **8.32 µJ / inference**. |

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

## 5. Thống Kê PPA Thực Tế Trên FPGA (AMD Xilinx Zynq-7000 `xc7z010-1`)

Kết quả tổng hợp và Place & Route vật lý hoàn chỉnh từ AMD Vivado 2024.2:

| Chỉ số PPA | Giá trị thực tế | Giới hạn Zynq-7010 | Tỷ lệ sử dụng | Nhận xét chuyên môn |
| :--- | :---: | :---: | :---: | :--- |
| **Slice LUTs** | **2,958** | 17,600 | **16.81%** | Cực kỳ gọn nhẹ, còn trống 83.19% diện tích chip |
| **Slice Registers (FF)** | **2,280** | 35,200 | **6.48%** | Logic đường ống gọn gàng, cân bằng tải cao |
| **Block RAM (RAMB36E1)** | **26** | 60 | **43.33%** | Chứa trọn 51 KB TCDM on-chip, 0 cần DRAM ngoài |
| **Khối cứng DSP48E1** | **0** | 80 | **0.00%** | **ZERO-DSP TUYỆT ĐỐI (100% tài nguyên DSP tự do)** |
| **Xung nhịp ký kết an toàn** | **100.0 MHz** | - | - | ✅ **Timing Met: WNS = +1.408 ns (0 vi phạm)** |
| **Tần số tối đa ($F_{max}$)** | **116.39 MHz** | - | - | Giới hạn bởi đường CPU fabric writeback |
| **Thời gian suy luận (Latency)**| **$127.96\ \mu\text{s}$** | - | - | $12,796$ chu kỳ clock / ảnh |
| **Thông lượng xử lý (FPS)** | **$7,815\text{ FPS}$** | - | - | Nhanh gấp ~130 lần chuẩn video 60 FPS |
| **Công suất động (Dynamic)** | **$65.0\text{ mW}$** | - | - | Tiết kiệm vượt trội (Junction Temp 26.8 °C) |
| **Năng lượng / Lần đoán** | **$8.32\ \mu\text{J}$** | - | - | **Chuẩn Ultra-Low-Power TinyML thế giới** |
| **Độ chính xác (MNIST 10k)** | **$93.61\%$** | - | - | Tương đương INT8 toán học lý tưởng (93.59%) |
