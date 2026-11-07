# BÁO CÁO ĐÁNH GIÁ VẬT LÝ NHÁNH: V0-BASELINE (INITIAL RTL & SOFTWARE BASELINE)

**Thiết kế:** Hệ thống vi mạch Mini-PULP SoC ban đầu trước khi tối ưu hóa  
**Cuộc thi:** HCMUTE Edge AI Design Challenge (Kế hoạch số 38/KH-ĐĐT)  
**Tác giả:** Nguyễn Văn Thức (24161421)  
**Target Device:** AMD Xilinx Zynq-7000 `xc7z010clg400-1` (Digilent Zybo Z7-10)  
**Công cụ:** AMD Vivado 2024.2 (Physical Synthesis & Implementation)

---

## 1. TỔNG HỢP CHỈ SỐ PPA (POWER - PERFORMANCE - AREA)

| Thông số kỹ thuật | Kết quả đạt được | Giới hạn thiết bị (Zynq-7010) | Tỷ lệ sử dụng | Nhận xét chuyên môn |
| :--- | :--- | :--- | :--- | :--- |
| **Slice LUTs** | **3,264** | 17,600 | **18.55%** | Mảng PE ban đầu mang encoder riêng biệt |
| **Slice Registers (FF)** | **1,979** | 35,200 | **5.62%** | Chưa có thanh ghi đường ống PE MAC |
| **Block RAM (RAMB36E1)** | **18** | 60 | **30.00%** | Chứa mã lệnh và một phần dữ liệu on-chip |
| **DSP48E1 Multipliers** | **0** | 80 | **0.00%** | Mạch nhân xấp xỉ ban đầu chưa tối ưu hóa |
| **Xung nhịp ràng buộc** | **100.0 MHz** | - | - | ❌ **TIMING FAILED: WNS = -5.000 ns** |
| **Tần số hoạt động thực tế** | **~50.0 MHz** | - | - | Đường trễ tổ hợp dài qua 20 tầng logic |
| **Thời gian suy luận (CPU C)**| **5,081.60 µs (5.08 ms)**| - | - | ~508,160 chu kỳ clock thực thi phần mềm C |
| **Thông lượng xử lý (CPU FPS)**| **196 FPS** | - | - | Không đáp ứng yêu cầu xử lý thời gian thực |
| **Công suất động ($P_{\text{dyn}}$)**| **98.0 mW** | - | - | Tiêu hao chuyển mạch do logic tổ hợp sâu |
| **Năng lượng / Lượt suy luận**| **162.60 µJ / ảnh** | - | - | Tiêu hao năng lượng cao khi chạy phần mềm |
| **Độ chính xác MNIST (10k)** | **93.59%** | - | - | Khớp mô hình toán học lượng tử hóa |
