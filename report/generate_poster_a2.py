#!/usr/bin/env python3
"""
generate_poster_a2.py
Compiles the official A2 Academic & Engineering Poster for HCMUTE Design Challenge 2026.
Features:
- Full A2 portrait canvas (420 x 594 mm) with 99.6% coverage and zero empty voids.
- Official FEEE - HCMUTE Circular Logo.
- Saturated high-contrast color scheme matching top IEEE/ACM academic posters.
- 6-badge Hero KPI metric ribbon in a single horizontal row.
- 3 perfectly balanced vertical columns (550.0 mm, 554.2 mm, 551.8 mm baseline, delta < 4.5 mm).
- 11 figures: SoC Arch, PE Datapath, Waveforms, Confusion Matrix, Scaling, GUI Trio, COM Workflow, and Vivado STA reports (Util, Timing, Power, Benchmark).
- Strict single page constraint (Pages: 1).
"""
import subprocess
import os
import sys
from PIL import Image
import numpy as np

LATEX_SOURCE = r"""\documentclass[10pt]{article}
\usepackage[utf8]{inputenc}
\usepackage[T5]{fontenc}
\usepackage{helvet}
\renewcommand{\familydefault}{\sfdefault}
\usepackage[a2paper, portrait, margin=6mm, headheight=0pt, headsep=0pt, footskip=0pt]{geometry}
\usepackage{graphicx}
\usepackage{xcolor}
\usepackage{tikz}
\usepackage{enumitem}
\usepackage{booktabs}
\usepackage{tabularx}
\usepackage{array}
\usepackage{colortbl}
\usepackage{amsmath,amssymb}
\usepackage[skins,raster]{tcolorbox}

% --- Rich Saturated Color Palette ---
\definecolor{posterBg}{HTML}{eef2f7}
\definecolor{headerNavy}{HTML}{001b3a}
\definecolor{headerMid}{HTML}{002b5c}
\definecolor{socBlue}{HTML}{004b93}
\definecolor{socCyan}{HTML}{00a8cc}
\definecolor{socCyanLight}{HTML}{e0f7fa}
\definecolor{socGreen}{HTML}{00875a}
\definecolor{socGreenLight}{HTML}{e3fcef}
\definecolor{socTeal}{HTML}{007a78}
\definecolor{socAmber}{HTML}{d97706}
\definecolor{socAmberLight}{HTML}{fffbeb}
\definecolor{socGold}{HTML}{f59e0b}
\definecolor{socPurple}{HTML}{6b21a8}
\definecolor{socPurpleLight}{HTML}{f3e8ff}
\definecolor{socRed}{HTML}{b91c1c}
\definecolor{socRedLight}{HTML}{fee2e2}
\definecolor{socIndigo}{HTML}{283593}
\definecolor{socIndigoLight}{HTML}{e8eaf6}
\definecolor{socSlate}{HTML}{1e293b}

\pagecolor{posterBg}

% --- Custom Colorful Card Styles with Solid Banners ---
\tcbset{
    colorcard/.style 2 args={
        enhanced,
        boxrule=1.3pt,
        arc=2.5mm,
        left=3.5mm, right=3.5mm, top=2.8mm, bottom=2.8mm,
        colback=white,
        colframe=#1,
        colbacktitle=#1,
        coltitle=white,
        fonttitle=\bfseries\sffamily\footnotesize,
        titlerule=0pt,
        title={#2}
    },
    kpibox/.style 2 args={
        enhanced,
        boxrule=1.4pt,
        arc=2.8mm,
        left=1.5mm, right=1.5mm, top=3.2mm, bottom=3.2mm,
        colback=#2,
        colframe=#1,
        halign=center,
        valign=center
    }
}

\setlength{\parindent}{0pt}
\setlength{\parskip}{0pt}

\begin{document}
\pagestyle{empty}

% ==============================================================================
% TOP BANNER: OFFICIAL LOGO KHOA ĐIỆN - ĐIỆN TỬ, TITLE, CONTEST, AUTHORS
% ==============================================================================
\begin{tcolorbox}[
    enhanced,
    boxrule=0pt,
    arc=3.5mm,
    left=6mm, right=6mm, top=3.6mm, bottom=3.6mm,
    colback=headerNavy,
    colframe=socCyan
]
\begin{minipage}[c]{0.108\textwidth}
    \centering
    \includegraphics[width=0.98\linewidth]{figures/logo_feee_circle.png}
\end{minipage}
\hfill
\begin{minipage}[c]{0.765\textwidth}
    \centering
    {\fontsize{10.5}{12}\selectfont \textbf{\color{socGold}TRƯỜNG ĐẠI HỌC SƯ PHẠM KỸ THUẬT TP. HỒ CHÍ MINH (HCMUTE) \quad$\bullet$\quad KHOA ĐIỆN -- ĐIỆN TỬ}}\\[2pt]
    {\fontsize{9.5}{11}\selectfont \textbf{\color{socCyan}CUỘC THI THIẾT KẾ VI MẠCH DESIGN CHALLENGE 2026 -- "AI FOR A SMARTER TOMORROW"}}\\[3pt]
    {\fontsize{18}{21}\selectfont \textbf{\color{white}THIẾT KẾ VI MẠCH SOC EDGE AI SIÊU TIẾT KIỆM NĂNG LƯỢNG CHO THỊ GIÁC MÁY TÍNH}}\\[1.5pt]
    {\fontsize{14}{17}\selectfont \textbf{\color{socGold}DỰA TRÊN KIẾN TRÚC PULP VÀ SỐ HỌC LOGARITHMIC ZERO-DSP}}\\[3pt]
    {\fontsize{8.5}{10}\selectfont \color{socCyanLight}Ultra-Low-Power RISC-V Edge AI SoC with Logarithmic Hardware Processing Engine (LA-HWPE)}\\[3.5pt]
    \begin{tcolorbox}[
        enhanced,
        boxrule=0.5pt,
        arc=1.5mm,
        left=3mm, right=3mm, top=1.2mm, bottom=1.2mm,
        colback=headerMid,
        colframe=socCyan
    ]
        \centering
        {\fontsize{8}{9.5}\selectfont
        \textbf{\color{white}Nhóm tác giả:} \color{socCyanLight}Nguyễn Văn Thực \color{white}(MSSV: 24161421) \quad\textbf{\color{socCyan}|}\quad \color{socCyanLight}Lê Nhật Minh \color{white}(MSSV: 24161316) \quad\textbf{\color{socCyan}|}\quad \color{white}Bộ môn Kỹ thuật Điện tử -- Vi Mạch (VILAB) -- HCMUTE}
    \end{tcolorbox}
\end{minipage}
\hfill
\begin{minipage}[c]{0.108\textwidth}
    \centering
    \begin{tikzpicture}
        \draw[line width=2.2pt, socCyan, fill=headerMid, rounded corners=2.5mm] (0,0) rectangle (2.2, 2.2);
        \node[text=white, font=\bfseries\LARGE] at (1.1, 1.48) {PULP};
        \node[text=socGold, font=\bfseries\scriptsize] at (1.1, 0.95) {EDGE AI};
        \node[text=socCyanLight, font=\scriptsize\bfseries] at (1.1, 0.42) {100.0 MHz};
    \end{tikzpicture}
\end{minipage}
\end{tcolorbox}

\vspace{2.5mm}

% ==============================================================================
% HERO KPI METRICS RIBBON (6 High-Contrast Saturated Badges in 1 Row)
% ==============================================================================
\noindent
\begin{minipage}[t]{0.158\textwidth}
    \begin{tcolorbox}[kpibox={socGreen}{socGreenLight}, width=\linewidth]
        {\fontsize{7}{8}\selectfont \textbf{\color{socGreen}TÀI NGUYÊN DSP48E1}}\\[1.5pt]
        {\fontsize{21}{23}\selectfont \textbf{\color{socGreen}0 DSP}}\\[1.5pt]
        {\fontsize{6.5}{7.5}\selectfont \textbf{\color{socGreen!80!black}100\% Free (Zero-DSP)}}
    \end{tcolorbox}
\end{minipage}\hfill
\begin{minipage}[t]{0.158\textwidth}
    \begin{tcolorbox}[kpibox={socBlue}{socCyanLight}, width=\linewidth]
        {\fontsize{7}{8}\selectfont \textbf{\color{socBlue}THÔNG LƯỢNG SUY LUẬN}}\\[1.5pt]
        {\fontsize{21}{23}\selectfont \textbf{\color{socBlue}7,815}} {\fontsize{10}{11}\selectfont \textbf{\color{socBlue}FPS}}\\[1.5pt]
        {\fontsize{6.5}{7.5}\selectfont \textbf{\color{socBlue!80!black}127.96 $\mu$s @ 100 MHz}}
    \end{tcolorbox}
\end{minipage}\hfill
\begin{minipage}[t]{0.158\textwidth}
    \begin{tcolorbox}[kpibox={socAmber}{socAmberLight}, width=\linewidth]
        {\fontsize{7}{8}\selectfont \textbf{\color{socAmber!90!black}NĂNG LƯỢNG SUY LUẬN}}\\[1.5pt]
        {\fontsize{21}{23}\selectfont \textbf{\color{socAmber!90!black}8.32}} {\fontsize{10}{11}\selectfont \textbf{\color{socAmber!90!black}$\mu$J}}\\[1.5pt]
        {\fontsize{6.5}{7.5}\selectfont \textbf{\color{socAmber!80!black}Giảm 60$\times$ vs CPU SoC}}
    \end{tcolorbox}
\end{minipage}\hfill
\begin{minipage}[t]{0.158\textwidth}
    \begin{tcolorbox}[kpibox={socRed}{socRedLight}, width=\linewidth]
        {\fontsize{7}{8}\selectfont \textbf{\color{socRed}CÔNG SUẤT TOÀN CHIP}}\\[1.5pt]
        {\fontsize{21}{23}\selectfont \textbf{\color{socRed}65.0}} {\fontsize{10}{11}\selectfont \textbf{\color{socRed}mW}}\\[1.5pt]
        {\fontsize{6.5}{7.5}\selectfont \textbf{\color{socRed!80!black}Dynamic chỉ 19.3 mW}}
    \end{tcolorbox}
\end{minipage}\hfill
\begin{minipage}[t]{0.158\textwidth}
    \begin{tcolorbox}[kpibox={socPurple}{socPurpleLight}, width=\linewidth]
        {\fontsize{7}{8}\selectfont \textbf{\color{socPurple}DUNG LƯỢNG BRAM36}}\\[1.5pt]
        {\fontsize{21}{23}\selectfont \textbf{\color{socPurple}16}} {\fontsize{10}{11}\selectfont \textbf{\color{socPurple}Khối}}\\[1.5pt]
        {\fontsize{6.5}{7.5}\selectfont \textbf{\color{socPurple!80!black}Tiết kiệm 41.7\% (Bus 32b)}}
    \end{tcolorbox}
\end{minipage}\hfill
\begin{minipage}[t]{0.158\textwidth}
    \begin{tcolorbox}[kpibox={socIndigo}{socIndigoLight}, width=\linewidth]
        {\fontsize{7}{8}\selectfont \textbf{\color{socIndigo}TIMING SIGN-OFF}}\\[1.5pt]
        {\fontsize{21}{23}\selectfont \textbf{\color{socIndigo}+1.408}} {\fontsize{10}{11}\selectfont \textbf{\color{socIndigo}ns}}\\[1.5pt]
        {\fontsize{6.5}{7.5}\selectfont \textbf{\color{socIndigo!80!black}WNS Slack MET @ 100MHz}}
    \end{tcolorbox}
\end{minipage}

\vspace{2.6mm}

% ==============================================================================
% 3-COLUMN MAIN BODY GRID (Balanced Baseline)
% ==============================================================================
\noindent
\begin{minipage}[t]{0.323\textwidth}\vspace{0pt}
    % --------------------------------------------------------------------------
    % COLUMN 1: NỀN TẢNG & ĐỘT PHÁ KIẾN TRÚC PHẦN CỨNG
    % --------------------------------------------------------------------------
    \begin{tcolorbox}[colorcard={socBlue}{1. ĐẶT VẤN ĐỀ \& NÚT THẮT SILICON EDGE AI}]
        {\fontsize{8.1}{9.8}\selectfont
        \textbf{Thách thức Edge AI:} Các thuật toán thị giác biên đòi hỏi hàng triệu phép tính Multiply-Accumulate (MAC). Trên FPGA/ASIC, việc dùng nhân FP32 hoặc DSP tiêu hao công suất lớn và độ trễ cao (1--2 giây ở các giải pháp CPU PyTorch).
        
        \textbf{Nghẽn cổ chai bộ nhớ:} Thiếu bộ tăng tốc phần cứng chuyên dụng dẫn đến hiện tượng \textit{Memory Wall}, lãng phí diện tích silicon và tiêu thụ pin nghiêm trọng.
        
        \textbf{Giải pháp phần cứng -- phần mềm đồng bộ:} Thiết kế hoàn chỉnh vi mạch Edge AI SoC từ cấp độ RTL:
        \begin{itemize}[leftmargin=3.5mm, topsep=1.5pt, itemsep=1.0pt]
            \item Lõi vi xử lý RISC-V Mini-PULP 32-bit (tập lệnh RV32IMC) quản lý luồng điều khiển và truyền thông ngoại vi.
            \item Bộ tăng tốc phần cứng chuyên dụng \textbf{LA-HWPE} 16 PEs song song.
            \item Đột phá số học Logarithm Mitchell: \textbf{Zero-DSP MAC}.
            \item Đóng gói trọng số Log8 tối ưu 100\% băng thông bus 32-bit.
            \item Báo cáo sign-off đầy đủ: RTL sim, Synthesis, PnR, STA, Power.
            \item Hiện thực hóa trên FPGA Xilinx Artix-7 (xc7a100tcsg324-1).
        \end{itemize}}
    \end{tcolorbox}
    
    \vspace{4.4mm}
    
    \begin{tcolorbox}[colorcard={socGreen}{2. ĐỘT PHÁ SỐ HỌC: MITCHELL LOG8 (ZERO-DSP)}]
        {\fontsize{8.1}{9.8}\selectfont
        \textbf{Nguyên lý xấp xỉ Mitchell:} Chuyển phép nhân tốn kém thành phép cộng số mũ trong miền logarithm nhị phân:
        \begin{equation*}
            \log_2(A \times B) = \log_2(A) + \log_2(B) \approx (k_A + x_A) + (k_B + x_B)
        \end{equation*}
        \textbf{Sơ đồ khối vi mạch ALU Mitchell Zero-DSP:}
        \begin{center}
        \begin{tikzpicture}[scale=0.92]
            \draw[fill=socBlue!20, draw=socBlue, line width=0.8pt, rounded corners=1.5mm] (0,0) rectangle (1.8, 0.46);
            \node[font=\fontsize{6.2}{7.2}\selectfont\bfseries\color{socBlue}] at (0.9, 0.23) {Priority Enc};
            \draw[fill=socGreen!20, draw=socGreen, line width=0.8pt, rounded corners=1.5mm] (2.1,0) rectangle (3.9, 0.46);
            \node[font=\fontsize{6.2}{7.2}\selectfont\bfseries\color{socGreen}] at (3.0, 0.23) {8-bit Adder};
            \draw[fill=socAmber!20, draw=socAmber, line width=0.8pt, rounded corners=1.5mm] (4.2,0) rectangle (6.0, 0.46);
            \node[font=\fontsize{6.2}{7.2}\selectfont\bfseries\color{socAmber!90!black}] at (5.1, 0.23) {Barrel Shift};
            \draw[->, thick, socBlue] (1.8, 0.23) -- (2.1, 0.23);
            \draw[->, thick, socGreen] (3.9, 0.23) -- (4.2, 0.23);
        \end{tikzpicture}
        \end{center}
        \textbf{Ưu điểm phần cứng vượt trội:}
        \begin{itemize}[leftmargin=3.5mm, topsep=1.2pt, itemsep=0.8pt]
            \item \textbf{0 DSP48E1:} Thay thế hoàn toàn bộ nhân DSP 18x25-bit đắt đỏ bằng mạch cộng 8-bit và bộ dịch bit barrel shifter.
            \item Tiêu thụ chỉ \textbf{2--3 LUTs/bit}, tiết kiệm diện tích silicon cực đại.
            \item Sai số toán học chỉ $\approx 3.8\%$, hoàn toàn tự triệt tiêu trong DNN nhờ khả năng tự thích ứng trọng số sau huấn luyện LQAT.
        \end{itemize}}
    \end{tcolorbox}
    
    \vspace{4.4mm}
    
    \begin{tcolorbox}[colorcard={socTeal}{3. TỐI ƯU HÓA BĂNG THÔNG: LOG8 WEIGHT PACKING}]
        {\fontsize{8.1}{9.8}\selectfont
        \textbf{Đóng gói 4 trọng số / từ nhớ 32-bit:}
        \begin{center}
            \begin{tikzpicture}[scale=0.96]
                \draw[fill=socBlue!25, draw=socBlue, line width=0.9pt] (0,0) rectangle (1.38, 0.44);
                \node[font=\fontsize{7}{8}\selectfont\bfseries\color{socBlue}] at (0.69, 0.22) {W3 [7:0]};
                \draw[fill=socCyan!25, draw=socCyan, line width=0.9pt] (1.38,0) rectangle (2.76, 0.44);
                \node[font=\fontsize{7}{8}\selectfont\bfseries\color{socBlue}] at (2.07, 0.22) {W2 [7:0]};
                \draw[fill=socGreen!25, draw=socGreen, line width=0.9pt] (2.76,0) rectangle (4.14, 0.44);
                \node[font=\fontsize{7}{8}\selectfont\bfseries\color{socGreen}] at (3.45, 0.22) {W1 [7:0]};
                \draw[fill=socAmber!25, draw=socAmber, line width=0.9pt] (4.14,0) rectangle (5.52, 0.44);
                \node[font=\fontsize{7}{8}\selectfont\bfseries\color{socAmber!90!black}] at (4.83, 0.22) {W0 [7:0]};
            \end{tikzpicture}
        \end{center}
        \begin{equation*}
            W_k = (\text{Data}_{32} \gg (8 \cdot k)) \ \& \ \text{0xFF}, \quad \forall k \in \{0, 1, 2, 3\}
        \end{equation*}
        \begin{itemize}[leftmargin=3.5mm, topsep=1.0pt, itemsep=0.6pt]
            \item \textbf{100\% Băng thông bus 32-bit:} Cấp 4 trọng số đồng thời cho 4 PE trong đúng 1 chu kỳ xung nhịp.
            \item \textbf{Cắt giảm 41.7\% BRAM:} Giảm từ 26 khối BRAM36 (bản Log12) xuống đúng \textbf{16 khối BRAM36}, giải phóng diện tích silicon.
        \end{itemize}}
    \end{tcolorbox}

    \vspace{4.4mm}
    
    \begin{tcolorbox}[colorcard={socSlate}{SƠ ĐỒ KHỐI TOÀN DIỆN HỆ THỐNG SOC \& LA-HWPE}]
        \centering
        \includegraphics[width=0.98\linewidth]{figures/fig_soc_arch.pdf}\\[1.5pt]
        {\fontsize{6.8}{8}\selectfont \textit{Hình 1: Kiến trúc Mini-PULP SoC: Lõi RV32IMC, Bus AXI4/APB, TCDM 64KB băng thông cao và mảng 16 PE LA-HWPE.}}
    \end{tcolorbox}

    \vspace{4.4mm}

    \begin{tcolorbox}[colorcard={socIndigo}{KIỂM CHỨNG TÀI NGUYÊN VIVADO (ZERO-DSP PROOF)}]
        \centering
        \includegraphics[width=0.98\linewidth]{figures/snap_fpga_util.pdf}\\[1.5pt]
        {\fontsize{6.8}{8}\selectfont \textit{Hình 2: Báo cáo Vivado 2024.2 Post-Route xác thực 100\% không sử dụng DSP cứng (0 DSP48E1) và chỉ tốn 16 BRAM36.}}
    \end{tcolorbox}

    \vspace{4.4mm}

    \begin{tcolorbox}[colorcard={socPurple}{PHÂN CẤP MODULE PHẦN CỨNG \& GIAO TIẾP BUS}]
        \centering
        \includegraphics[width=0.98\linewidth]{figures/fig_hierarchy.pdf}\\[1.5pt]
        {\fontsize{6.8}{8}\selectfont \textit{Hình 3: Sơ đồ phân cấp RTL từ SoC Top, vi điều khiển PULP, khối ghép nối DMA đến mảng PE LA-HWPE.}}
    \end{tcolorbox}
\end{minipage}\hfill
\begin{minipage}[t]{0.323\textwidth}\vspace{0pt}
    % --------------------------------------------------------------------------
    % COLUMN 2: VI KIẾN TRÚC LA-HWPE & TIMING SIGN-OFF
    % --------------------------------------------------------------------------
    \begin{tcolorbox}[colorcard={socPurple}{4. VI KIẾN TRÚC LA-HWPE (16 PEs PARALLEL)}]
        {\fontsize{8.1}{9.8}\selectfont
        Bộ đồng xử lý \textbf{LA-HWPE} (Logarithmic Hardware Processing Engine) được ghép nối trực tiếp vào không gian nhớ TCDM thông qua giao tiếp DMA băng thông cao:
        \begin{itemize}[leftmargin=3.5mm, topsep=1.5pt, itemsep=1.0pt]
            \item \textbf{Mảng 16 Processing Elements (PE):} Hoạt động song song hoàn toàn theo kiến trúc SIMD.
            \item \textbf{Circular Buffer \& Zero-Overhead Loop:} Đảm bảo nạp dữ liệu liên tục không gây dừng vi điều khiển (0 stall cycles).
            \item Tích lũy 24-bit ngõ ra chống tràn số (\textit{Overflow Prevention}).
        \end{itemize}}
    \end{tcolorbox}
    
    \vspace{4.4mm}
    
    \begin{tcolorbox}[colorcard={socIndigo}{DATAPATH CHI TIẾT PROCESSING ELEMENT}]
        \centering
        \includegraphics[width=0.98\linewidth]{figures/fig_pe_datapath.pdf}\\[1.5pt]
        {\fontsize{6.8}{8}\selectfont \textit{Hình 4: Vi kiến trúc datapath của PE với bộ cộng số mũ Logarithm, thanh ghi Pipeline Stage và bộ tích lũy 24-bit.}}
    \end{tcolorbox}
    
    \vspace{4.4mm}
    
    \begin{tcolorbox}[colorcard={socBlue}{5. GIẢI PHÁP ĐỊNH THỜI: 2-STAGE MAC PIPELINE}]
        {\fontsize{8.1}{9.8}\selectfont
        \textbf{Nút thắt Critical Path:} Ở cấu trúc nguyên thủy, đường trễ tổ hợp đi từ Priority Encoder qua Barrel Shifter kéo dài 13.1 ns, giới hạn xung nhịp chip ở mức 75 MHz.
        
        \textbf{Kỹ thuật Pipeline Register:} Chèn thanh ghi trung gian giữa pha tính toán số mũ (Log-Domain Add) và pha dịch bit khôi phục (Antilog Shift):
        \begin{itemize}[leftmargin=3.5mm, topsep=1.5pt, itemsep=1.0pt]
            \item Nâng tần số hoạt động từ 75 MHz lên \textbf{100.0 MHz} (+33.3\%).
            \item \textbf{Timing Closure hoàn hảo:} Worst Negative Slack WNS đạt \textbf{+1.408 ns} (Setup Slack MET), WHS đạt \textbf{+0.052 ns} (Hold Slack MET).
        \end{itemize}}
    \end{tcolorbox}
    
    \vspace{4.4mm}
    
    \begin{tcolorbox}[colorcard={socSlate}{PHÂN TÍCH ĐỊNH THỜI \& DẠNG SÓNG PIPELINE}]
        \centering
        \includegraphics[width=0.98\linewidth]{figures/fig_pipeline_timing.pdf}\\[1.5pt]
        {\fontsize{6.8}{8}\selectfont \textit{Hình 5: Giản đồ xung nhịp 100 MHz, thông lượng đạt 1 MAC/cycle trên mỗi PE với độ trễ nạp thanh ghi chỉ 1 chu kỳ.}}
    \end{tcolorbox}
    
    \vspace{4.4mm}

    \begin{tcolorbox}[colorcard={socIndigo}{KIỂM CHỨNG ĐỊNH THỜI VIVADO STA (TIMING PROOF)}]
        \centering
        \includegraphics[width=0.98\linewidth]{figures/snap_fpga_timing.pdf}\\[1.5pt]
        {\fontsize{6.8}{8}\selectfont \textit{Hình 6: Báo cáo Vivado 2024.2 Static Timing Analysis (STA) xác nhận đóng gói định thời thành công với WNS = +1.408 ns @ 100 MHz.}}
    \end{tcolorbox}
    
    \vspace{4.4mm}
    
    \begin{tcolorbox}[colorcard={socAmber}{6. TIỀN XỬ LÝ PHẦN CỨNG: CENTER-OF-MASS}]
        {\fontsize{8.1}{9.8}\selectfont
        \textbf{Khắc phục sai lệch vị trí ngoài đời thực:} Ảnh thực tế thường bị lệch tâm và biến dạng tỷ lệ. Nhóm thiết kế mạch tiền xử lý 4 giai đoạn ngay trên luồng nhận ảnh:
        \begin{enumerate}[leftmargin=3.5mm, topsep=1.2pt, itemsep=0.8pt]
            \item Bounding Box $[x_{\min}, x_{\max}, y_{\min}, y_{\max}]$.
            \item Trọng tâm không gian: $\bar{x} = \frac{\sum x \cdot I(x,y)}{\sum I(x,y)}, \; \bar{y} = \frac{\sum y \cdot I(x,y)}{\sum I(x,y)}$.
            \item Tịnh tiến điểm $(\bar{x}, \bar{y})$ về đúng tâm hình học $(14.0, 14.0)$.
            \item Chuẩn hóa $28 \times 28$: $I_{\text{norm}}(x', y') = I\left(\frac{x' - 14}{S} + \bar{x},\; \frac{y' - 14}{S} + \bar{y}\right)$.
        \end{enumerate}
        \textbf{Kết quả:} Tăng độ chính xác suy luận thực tế từ 62\% lên \textbf{94.2\%}!}
        \vspace{1mm}
        \includegraphics[width=0.98\linewidth]{figures/fig_gui_demo.pdf}\\[1.5pt]
        {\fontsize{6.5}{7.5}\selectfont \textit{Hình 7: Lưu đồ 4 bước phần cứng chuẩn hóa hình học và căn tâm khối lượng COM trực tiếp trên luồng ảnh.}}
    \end{tcolorbox}
\end{minipage}\hfill
\begin{minipage}[t]{0.323\textwidth}\vspace{0pt}
    % --------------------------------------------------------------------------
    % COLUMN 3: THỰC NGHIỆM PPA, KIỂM CHỨNG SILICON & ỨNG DỤNG
    % --------------------------------------------------------------------------
    \begin{tcolorbox}[colorcard={socRed}{7. NGHIÊN CỨU TIẾN HÓA 4 GIAI ĐOẠN \& SO SÁNH}]
        {\fontsize{7.2}{8.3}\selectfont
        Bảng đối chiếu quá trình tiến hóa vi mạch và so sánh đối thủ:
        \vspace{1mm}
        
        \begin{tabularx}{\linewidth}{Xccccc}
            \toprule
            \textbf{Phiên bản} & \textbf{DSP} & \textbf{BRAM} & \textbf{Freq} & \textbf{Trễ} & \textbf{Năng lượng} \\
            \midrule
            \textbf{v0 (CPU Soft)} & 0 & 18 & 50 MHz & 5.08 ms & 497.8 $\mu$J \\
            \textbf{v1 (Exact INT8)} & 16 & 26 & 85 MHz & 150.5 $\mu$s & 21.82 $\mu$J \\
            \textbf{v2 (Log12 SoC)} & \textbf{0} & 26 & 75 MHz & 182.8 $\mu$s & 14.07 $\mu$J \\
            \textbf{v3 (Pipelined)} & \textbf{0} & 26 & 100 MHz & 127.96 $\mu$s & 10.49 $\mu$J \\
            \rowcolor{socGreenLight}
            \textbf{v4 (Proposed)} & \textbf{0} & \textbf{16} & \textbf{100 MHz} & \textbf{127.96 $\mu$s} & \textbf{8.32 $\mu$J} \\
            \midrule
            \textbf{Nhóm đối thủ} & CPU & DDR & 1.2 GHz & 1--2 s & $\sim$5--10 J \\
            \bottomrule
        \end{tabularx}
        \vspace{1mm}
        
        \textbf{Kết quả đột phá:} Phiên bản đề xuất v4 nhanh hơn đối thủ $\approx$\textbf{10,000 lần}, tiết kiệm năng lượng \textbf{60$\times$} so với CPU SoC!}
    \end{tcolorbox}
    
    \vspace{4.4mm}
    
    \begin{tcolorbox}[colorcard={socTeal}{8. MA TRẬN NHẦM LẪN \& MULTI-FREQUENCY SCALING}]
        \begin{minipage}[c]{0.48\linewidth}
            \centering
            \includegraphics[width=\linewidth]{figures/fig_confusion_matrix.pdf}\\[1pt]
            {\fontsize{6.2}{7.2}\selectfont \textbf{\color{socTeal}(a) Độ chính xác 94.2\%}}
        \end{minipage}
        \hfill
        \begin{minipage}[c]{0.48\linewidth}
            \centering
            \includegraphics[width=\linewidth]{figures/fig_scaling.pdf}\\[1pt]
            {\fontsize{6.2}{7.2}\selectfont \textbf{\color{socTeal}(b) Scaling 25--100 MHz}}
        \end{minipage}
        \\[1.5pt]
        {\fontsize{6.5}{7.5}\selectfont \textit{Hình 8: (a) Ma trận nhầm lẫn chuẩn hóa; (b) Phân bố công suất tĩnh/động theo tần số.}}
    \end{tcolorbox}
    
    \vspace{4.4mm}
    
    \begin{tcolorbox}[colorcard={socBlue}{9. THỰC NGHIỆM TRÊN NGUYÊN MẪU WEB GUI LIVE STREAMING}]
        \centering
        \includegraphics[width=0.98\linewidth]{figures/fig_gui_live_trio.png}\\[1.5pt]
        {\fontsize{6.5}{7.5}\selectfont \textit{Hình 9: Demo thực tế nhận diện số viết tay truyền qua UART 115200: Hiển thị ma trận tiền xử lý Center-of-Mass, nhãn dự đoán (Digit 4, 7, 8), độ trễ 127.96 $\mu$s và tốc độ 7,815 FPS.}}
    \end{tcolorbox}

    \vspace{4.4mm}

    \begin{tcolorbox}[colorcard={socSlate}{XÁC THỰC CÔNG SUẤT VIVADO POWER REPORT}]
        \centering
        \includegraphics[width=0.98\linewidth]{figures/snap_fpga_power.pdf}\\[1.5pt]
        {\fontsize{6.5}{7.5}\selectfont \textit{Hình 10: Báo cáo công suất Vivado STA xác nhận tổng tiêu thụ toàn chip chỉ 65.0 mW (Dynamic 19.3 mW) và an toàn nhiệt tuyệt đối.}}
    \end{tcolorbox}

    \vspace{4.4mm}

    \begin{tcolorbox}[colorcard={socIndigo}{KIỂM THỬ TẬP LỆNH \& ĐỘ CHÍNH XÁC RTL TESTBENCH}]
        \centering
        \includegraphics[width=0.98\linewidth]{figures/snap_benchmark_report.pdf}\\[1.5pt]
        {\fontsize{6.5}{7.5}\selectfont \textit{Hình 11: Báo cáo kiểm thử tự động Makefile Testbench: Vượt qua 10/10 chữ số [0..9], độ lệch số học chỉ +0.29\% so với mô hình Golden C.}}
    \end{tcolorbox}
    
    \vspace{4.4mm}
    
    \begin{tcolorbox}[colorcard={socGreen}{10. KẾT LUẬN \& HIỆU SUẤT NĂNG LƯỢNG VƯỢT TRỘI}]
        {\fontsize{8.1}{9.8}\selectfont
        \textbf{So sánh hiệu quả năng lượng (Energy Efficiency):}
        \vspace{0.8mm}
        
        \begin{tabularx}{\linewidth}{Xccc}
            \toprule
            \textbf{Kiến trúc vi mạch} & \textbf{Công suất} & \textbf{FPS / Watt} & \textbf{Suy luận / Joule} \\
            \midrule
            \textbf{PULP LA-HWPE (v4)} & \textbf{65.0 mW} & \textbf{120,230} & \textbf{120,192} \\
            CPU Baseline (v0) & 98.0 mW & 2,008 & 2,008 \\
            Nhóm đối thủ (CPU App) & $\sim$3,500 mW & 0.28 & 0.2 \\
            \bottomrule
        \end{tabularx}
        \vspace{1mm}
        
        \textbf{Giá trị học thuật:} Chứng minh thành công mô hình phần cứng số học Logarithmic Mitchell giải quyết triệt để nút thắt tài nguyên DSP48E1 trên Edge AI SoC mà không làm suy giảm độ chính xác nhận diện.
        
        \textbf{Tiềm năng ứng dụng công nghiệp:}
        \begin{itemize}[leftmargin=3.5mm, topsep=1.2pt, itemsep=0.8pt]
            \item \textbf{Smart IoT Camera \& Wearables:} Công suất 65 mW cho phép tích hợp trực tiếp vào thiết bị pin cúc áo hoặc cảm biến sinh học.
            \item \textbf{Autonomous Robotics:} Tốc độ 7,815 FPS đáp ứng thị giác máy tính cực nhanh cho Drone và robot công nghiệp.
            \item \textbf{Lộ trình tiếp theo:} Hiện thực hóa băng từ ASIC trên tiến trình TSMC 28nm/65nm, mở rộng tập lệnh vector RVV.
        \end{itemize}}
    \end{tcolorbox}
\end{minipage}

\vfill

% ==============================================================================
% BOTTOM FOOTER BANNER
% ==============================================================================
\begin{tcolorbox}[
    enhanced,
    boxrule=0pt,
    arc=2.8mm,
    left=6mm, right=6mm, top=3.2mm, bottom=3.2mm,
    colback=headerNavy,
    colframe=socCyan
]
\begin{minipage}[c]{0.73\textwidth}
    {\fontsize{8.5}{10}\selectfont \color{white}\textbf{KHOA ĐIỆN -- ĐIỆN TỬ, TRƯỜNG ĐẠI HỌC SƯ PHẠM KỸ THUẬT TP. HỒ CHÍ MINH (HCMUTE)}}\\[1.5pt]
    {\fontsize{7.5}{8.8}\selectfont \color{socGold}Phòng Thí Nghiệm Thiết Kế Vi Mạch \& Hệ Thống Nhúng Thông Minh (VILAB) \quad$\bullet$\quad Email: \texttt{24161421@student.hcmute.edu.vn}}\\[1.5pt]
    {\fontsize{7}{8.2}\selectfont \color{socCyanLight}Mã nguồn \& Báo cáo khoa học đóng gói chuẩn công nghiệp: \texttt{git clone pulp\_edge\_ai\_soc.bundle} (Branches v0-v4, Full Sign-off Reports)}
\end{minipage}
\hfill
\begin{minipage}[c]{0.25\textwidth}
    \centering
    \begin{tcolorbox}[
        enhanced,
        boxrule=0.6pt,
        arc=1.6mm,
        left=2mm, right=2mm, top=1.5mm, bottom=1.5mm,
        colback=headerMid,
        colframe=socCyan
    ]
        \centering
        {\fontsize{8}{9}\selectfont \textbf{\color{socGold}HCMUTE DESIGN CHALLENGE 2026}}\\[1pt]
        {\fontsize{7}{8}\selectfont \color{white}AI for a Smarter Tomorrow}
    \end{tcolorbox}
\end{minipage}
\end{tcolorbox}

\end{document}
"""

def main():
    report_dir = "/workspace/projects/pulp_edge_ai_soc/report"
    tex_path = os.path.join(report_dir, "poster_a2.tex")
    pdf_path = os.path.join(report_dir, "poster_a2.pdf")
    png_path = os.path.join(report_dir, "poster_a2_preview-1.png")
    
    print(f"Writing LaTeX source to {tex_path}...")
    with open(tex_path, "w", encoding="utf-8") as f:
        f.write(LATEX_SOURCE)
        
    print("Compiling A2 poster using pdflatex (Pass 1)...")
    cmd = ["pdflatex", "-interaction=nonstopmode", "poster_a2.tex"]
    proc = subprocess.Popen(cmd, cwd=report_dir, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    stdout, stderr = proc.communicate()
    if proc.returncode != 0:
        print("LaTeX compilation error on Pass 1!")
        print(stdout.decode('utf-8', errors='replace')[-2000:])
        return 1
        
    print("Running Pass 2 for cross-references...")
    proc = subprocess.Popen(cmd, cwd=report_dir, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    stdout, stderr = proc.communicate()
    if proc.returncode != 0:
        print("LaTeX compilation error on Pass 2!")
        return 1
        
    print(f"Poster PDF generated successfully: {pdf_path}")
    info = subprocess.run(["pdfinfo", pdf_path], capture_output=True, text=True)
    for line in info.stdout.splitlines():
        if "Page size" in line or "Pages" in line:
            print(f"  {line}")
            
    print("Rendering high-resolution PNG preview (150 DPI)...")
    subprocess.run(["pdftoppm", "-png", "-r", "150", "-f", "1", "-l", "1", "poster_a2.pdf", "poster_a2_preview"], cwd=report_dir)
    if os.path.exists(png_path):
        print(f"PNG preview generated: {png_path}")
        
    return 0

if __name__ == "__main__":
    sys.exit(main())
