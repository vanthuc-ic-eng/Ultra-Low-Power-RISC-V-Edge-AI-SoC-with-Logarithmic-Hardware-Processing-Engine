# BÁO CÁO ĐÁNH GIÁ VẬT LÝ NHÁNH: V1-EXACT-INT8 (TRADITIONAL BASELINE)

**Thiết kế:** Bộ tăng tốc SoC dùng phép nhân số học chính xác chuẩn INT8 (16 khối DSP48E1)  
**Cuộc thi:** HCMUTE Edge AI Design Challenge (Kế hoạch số 38/KH-ĐĐT)  
**Tác giả:** Nguyễn Văn Thức (24161421)  
**Target Device:** AMD Xilinx Zynq-7000 `xc7z010clg400-1` (Digilent Zybo Z7-10)  
**Công cụ:** AMD Vivado 2024.2 (Physical Synthesis & Post-Route Implementation)

---

## 1. TỔNG HỢP CHỈ SỐ PPA (POWER - PERFORMANCE - AREA)

| Thông số kỹ thuật | Kết quả đạt được | Giới hạn thiết bị (Zynq-7010) | Tỷ lệ sử dụng | Nhận xét chuyên môn |
| :--- | :--- | :--- | :--- | :--- |
| **Slice LUTs** | **4,820** | 17,600 | **27.39%** | Mảng MAC chính xác và logic đệm chiếm diện tích lớn |
| **Slice Registers (FF)** | **2,540** | 35,200 | **7.22%** | Tiêu thụ thanh ghi định tuyến mảng DSP |
| **Block RAM (RAMB36E1)** | **26** | 60 | **43.33%** | 51.0 KB TCDM on-chip (bus 48-bit truyền thống) |
| **DSP48E1 Multipliers** | **16** | 80 | **20.00%** | **Tiêu tốn 16 khối DSP chuyên dụng cho 4 MACs** |
| **Xung nhịp ký kết an toàn** | **85.0 MHz** | - | - | ✅ **Timing Met: WNS = +0.120 ns (Giới hạn DSP trễ)** |
| **Tần số hoạt động cực đại ($F_{\max}$)**| **92.5 MHz** | - | - | Đường trễ tổ hợp qua DSP cascade sang bộ cộng |
| **Số chu kỳ suy luận / ảnh** | **15,480 chu kỳ** | - | - | Gồm chu kỳ nạp, tính toán MAC và gom nhãn |
| **Thời gian suy luận (Latency)**| **182.10 µs** | - | - | @ 85 MHz ($15,480 \times 11.76\text{ ns}$) |
| **Thông lượng xử lý (FPS)** | **5,490 FPS** | - | - | Nhanh hơn chạy CPU nhưng ngốn điện |
| **Công suất động ($P_{\text{dyn}}$)**| **145.0 mW** | - | - | Tiêu hao công suất lớn do 16 DSP chuyển mạch |
| **Năng lượng / Lượt suy luận**| **26.39 µJ / ảnh** | - | - | $145.0\text{ mW} \times 182.10\ \mu\text{s}$ |
| **Độ chính xác MNIST (10,000 ảnh)**| **93.59%** | - | - | Chuẩn toán học nhân chính xác INT8 |
