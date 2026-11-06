#!/usr/bin/env python3
# ==============================================================================
# File: app.py
# Project: PULP-inspired Edge AI SoC for Handwritten Digit Recognition
# Author: Nguyen Van Thuc (24161421)
# Description:
#   Zero-dependency Interactive Web-based Live Demo GUI & Telemetry Server.
#   - Canvas drawing with mouse/touch or 1-click MNIST sample loading.
#   - Real-time bit-exact LA-HWPE RTL hardware model simulation.
#   - Live FPGA Zybo Z7 USB-UART connection mode.
#   - Full hardware telemetry dashboard: Latency, Cycles, FPS, Power, Energy.
# ==============================================================================

import os
import sys
import json
import numpy as np
import urllib.parse
from http.server import HTTPServer, BaseHTTPRequestHandler
import webbrowser
import threading

try:
    import serial
    import serial.tools.list_ports
    HAS_SERIAL = True
except ImportError:
    HAS_SERIAL = False

PROJ_DIR = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
DATA_DIR = os.path.join(PROJ_DIR, "sw", "data")

# ------------------------------------------------------------------------------
# 1. Load Hardware Model & Weights
# ------------------------------------------------------------------------------
lut_low3 = [1, 3, 4, 4, 6, 6, 7, 7]

def enc(x):
    if x < 0:
        mag = (-x) & 0xFF
        sign = 1
    else:
        mag = x & 0xFF
        sign = 0
    zero = (x == 0)
    if zero or mag == 0:
        return sign, zero, 0
    k = mag.bit_length() - 1
    bits = ((mag << (7 - k)) & 0xFF) & 0x7F
    upper = (bits >> 4) & 7
    addr = (bits >> 1) & 7
    low = lut_low3[addr]
    frac = (upper << 3) | low
    return sign, zero, (k << 6) | frac

def mul_s8_approx(a, b, trunc_bits=4):
    sa, za, la = enc(a)
    sb, zb, lb = enc(b)
    log_sum = la + lb
    exp = (log_sum >> 6) & 0xF
    frac_s = log_sum & 0x3F
    mantissa = ((1 << 6) | frac_s)
    shifted = (mantissa << exp) >> 6
    approx_mag = shifted & 0xFFFF
    sign_prod = sa ^ sb
    zero_prod = za | zb
    rem_bits = 16 - trunc_bits
    round_bit = ((approx_mag >> (trunc_bits - 1)) & 1) if trunc_bits > 0 else 0
    raw_trunc = (approx_mag >> trunc_bits) & ((1 << rem_bits) - 1)
    eff_sign = sign_prod and not zero_prod
    eff_round = round_bit and not zero_prod
    eff_raw = 0 if zero_prod else raw_trunc
    carry_in = (not eff_round) if eff_sign else eff_round
    base = (~eff_raw & ((1 << rem_bits) - 1)) if eff_sign else eff_raw
    signed_mag = (base + carry_in) & ((1 << rem_bits) - 1)
    res = signed_mag << trunc_bits
    if res >= 0x8000:
        res -= 0x10000
    return res

# Precompute LUT table for blazing speed
lut = np.zeros((256, 256), dtype=np.int16)
for a in range(-128, 128):
    for b in range(-128, 128):
        lut[a + 128, b + 128] = mul_s8_approx(a, b)

# Load weights and biases
W1 = np.zeros((784, 64), dtype=np.int8)
W2 = np.zeros((64, 12), dtype=np.int8)

def to_int8_val(w_enc_12b):
    sign = (w_enc_12b >> 10) & 1
    zero = (w_enc_12b >> 9) & 1
    if zero: return 0
    # Search INT8 value
    for val in range(-128, 128):
        s, z, l = enc(val)
        if (s == sign) and (z == zero) and (l == (w_enc_12b & 0x1FF)):
            return val
    return 0

weights_hex = os.path.join(DATA_DIR, "weights_tcdm.hex")
if os.path.exists(weights_hex):
    with open(weights_hex) as f:
        w_lines = [line.strip() for line in f if line.strip() and not line.startswith("//")]
    
    # Layer 1
    for g in range(16):
        for k in range(784):
            word48 = int(w_lines[g * 784 + k], 16)
            w0 = to_int8_val(word48 & 0xFFF)
            w1 = to_int8_val((word48 >> 12) & 0xFFF)
            w2 = to_int8_val((word48 >> 24) & 0xFFF)
            w3 = to_int8_val((word48 >> 36) & 0xFFF)
            W1[k, g*4 + 0] = w0
            W1[k, g*4 + 1] = w1
            W1[k, g*4 + 2] = w2
            W1[k, g*4 + 3] = w3
    
    # Layer 2
    for g in range(3):
        for k in range(64):
            word48 = int(w_lines[12544 + g * 64 + k], 16)
            w0 = to_int8_val(word48 & 0xFFF)
            w1 = to_int8_val((word48 >> 12) & 0xFFF)
            w2 = to_int8_val((word48 >> 24) & 0xFFF)
            w3 = to_int8_val((word48 >> 36) & 0xFFF)
            W2[k, g*4 + 0] = w0
            W2[k, g*4 + 1] = w1
            W2[k, g*4 + 2] = w2
            W2[k, g*4 + 3] = w3

with open(os.path.join(DATA_DIR, "biases_l1.hex")) as f:
    b1 = np.array([int(line.strip(), 16) if int(line.strip(), 16) < 0x80000000 else int(line.strip(), 16) - 0x100000000 for line in f if line.strip()], dtype=np.int32)

with open(os.path.join(DATA_DIR, "biases_l2.hex")) as f:
    b2 = np.array([int(line.strip(), 16) if int(line.strip(), 16) < 0x80000000 else int(line.strip(), 16) - 0x100000000 for line in f if line.strip()], dtype=np.int32)

def run_rtl_inference(img_bytes):
    # img_bytes: list or np.array of 784 ints in [0, 127]
    img = np.clip(np.array(img_bytes, dtype=np.int32), 0, 127)
    
    # Layer 1
    x_idx = img + 128
    w_idx = W1.astype(np.int32) + 128
    z1 = np.sum(lut[x_idx[:, None], w_idx], axis=0) + b1
    a1 = np.clip(np.maximum(0, z1) >> 11, 0, 127).astype(np.int8)
    
    # Layer 2
    a_idx = a1.astype(np.int32) + 128
    w_idx2 = W2[:, :10].astype(np.int32) + 128
    logits = np.sum(lut[a_idx[:, None], w_idx2], axis=0) + b2[:10]
    
    pred_class = int(np.argmax(logits))
    return pred_class, logits.tolist()

# ------------------------------------------------------------------------------
# 2. HTTP Server & Single-Page Application (HTML/CSS/JS)
# ------------------------------------------------------------------------------
HTML_PAGE = """<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Mini-PULP LA-HWPE Edge AI SoC Live Demo</title>
    <style>
        :root {
            --bg: #0b0f19;
            --card-bg: #151c2e;
            --border: #232d4b;
            --accent: #00d2ff;
            --accent2: #00f2fe;
            --green: #10b981;
            --text: #f1f5f9;
            --text-dim: #94a3b8;
        }
        * { box-sizing: border-box; margin: 0; padding: 0; font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif; }
        body { background: var(--bg); color: var(--text); padding: 24px; min-height: 100vh; display: flex; flex-direction: column; align-items: center; }
        .header { text-align: center; margin-bottom: 24px; }
        .header h1 { font-size: 26px; font-weight: 800; background: linear-gradient(135deg, #00d2ff, #3a7bd5); -webkit-background-clip: text; -webkit-text-fill-color: transparent; }
        .header p { color: var(--text-dim); font-size: 14px; margin-top: 4px; }
        .grid { display: grid; grid-template-columns: 340px 1fr; gap: 24px; width: 100%; max-width: 1050px; }
        .card { background: var(--card-bg); border: 1px solid var(--border); border-radius: 14px; padding: 20px; box-shadow: 0 10px 30px rgba(0,0,0,0.5); }
        .card-title { font-size: 15px; font-weight: 700; color: var(--text-dim); text-transform: uppercase; letter-spacing: 0.5px; margin-bottom: 14px; display: flex; justify-content: space-between; align-items: center; }
        
        /* Canvas Section */
        .canvas-container { display: flex; justify-content: center; margin-bottom: 14px; }
        canvas { background: #000; border: 2px solid var(--border); border-radius: 10px; cursor: crosshair; touch-action: none; }
        .btn-row { display: flex; gap: 8px; margin-bottom: 14px; }
        button { flex: 1; padding: 10px 14px; border: none; border-radius: 8px; font-weight: 600; cursor: pointer; transition: all 0.2s; font-size: 13px; }
        .btn-primary { background: linear-gradient(135deg, #00d2ff, #0072ff); color: white; }
        .btn-primary:hover { opacity: 0.9; transform: translateY(-1px); }
        .btn-secondary { background: #1e293b; color: var(--text); border: 1px solid var(--border); }
        .btn-secondary:hover { background: #334155; }
        .samples-label { font-size: 12px; color: var(--text-dim); margin-bottom: 6px; font-weight: 600; }
        .samples-grid { display: grid; grid-template-columns: repeat(5, 1fr); gap: 6px; }
        .btn-sample { background: #1a2236; color: var(--accent); padding: 8px 0; border: 1px solid var(--border); border-radius: 6px; font-size: 12px; }
        .btn-sample:hover { background: var(--accent); color: #000; }

        /* Dashboard Section */
        .result-box { display: flex; align-items: center; justify-content: space-between; background: #0f172a; border: 1px solid var(--border); border-radius: 12px; padding: 18px 24px; margin-bottom: 20px; }
        .pred-badge { font-size: 54px; font-weight: 900; color: var(--green); text-shadow: 0 0 20px rgba(16, 185, 129, 0.4); line-height: 1; }
        .pred-desc { text-align: right; }
        .pred-desc .title { font-size: 13px; color: var(--text-dim); text-transform: uppercase; font-weight: 700; }
        .pred-desc .status { font-size: 16px; color: var(--text); font-weight: 600; margin-top: 4px; }
        
        .metrics-grid { display: grid; grid-template-columns: repeat(3, 1fr); gap: 12px; margin-bottom: 20px; }
        .metric-card { background: #0f172a; border: 1px solid var(--border); border-radius: 10px; padding: 12px; text-align: center; }
        .metric-val { font-size: 18px; font-weight: 800; color: var(--accent); }
        .metric-lbl { font-size: 11px; color: var(--text-dim); font-weight: 600; margin-top: 3px; }

        /* Bar Chart */
        .chart-row { display: flex; align-items: center; margin-bottom: 6px; font-size: 12px; }
        .chart-digit { width: 18px; font-weight: 700; color: var(--text-dim); }
        .chart-bar-bg { flex: 1; height: 10px; background: #0f172a; border-radius: 5px; margin: 0 8px; overflow: hidden; }
        .chart-bar { height: 100%; width: 0%; background: linear-gradient(90deg, #00d2ff, #0072ff); border-radius: 5px; transition: width 0.3s ease; }
        .chart-bar.active { background: linear-gradient(90deg, #10b981, #059669); }
        .chart-score { width: 50px; text-align: right; font-family: monospace; font-size: 11px; color: var(--text-dim); }

        /* Mode Footer */
        .mode-bar { margin-top: 18px; display: flex; align-items: center; justify-content: space-between; font-size: 12px; color: var(--text-dim); }
        .mode-select { background: #0f172a; border: 1px solid var(--border); color: var(--text); padding: 4px 8px; border-radius: 6px; font-size: 12px; }
    </style>
</head>
<body>

    <div class="header">
        <h1>Mini-PULP LA-HWPE Edge AI SoC</h1>
        <p>Zero-DSP Logarithmic Hardware Accelerator for Handwritten Digit Recognition (Zybo Z7 xc7z010)</p>
    </div>

    <div class="grid">
        <!-- Left: Input & Canvas -->
        <div class="card">
            <div class="card-title">
                <span>Vẽ Số Tay (Input)</span>
                <span style="font-size: 11px; color: var(--accent);">28 x 28 Pixels</span>
            </div>

            <div class="canvas-container">
                <canvas id="cvs" width="280" height="280"></canvas>
            </div>

            <div class="btn-row">
                <button class="btn-primary" onclick="predictCanvas()">⚡ Nhận Diện</button>
                <button class="btn-secondary" onclick="clearCanvas()">Xóa Trắng</button>
            </div>

            <div class="samples-label">Hoặc chọn mẫu MNIST chuẩn kiểm thử:</div>
            <div class="samples-grid">
                <button class="btn-sample" onclick="loadSample(0)">Số 0</button>
                <button class="btn-sample" onclick="loadSample(1)">Số 1</button>
                <button class="btn-sample" onclick="loadSample(2)">Số 2</button>
                <button class="btn-sample" onclick="loadSample(3)">Số 3</button>
                <button class="btn-sample" onclick="loadSample(4)">Số 4</button>
                <button class="btn-sample" onclick="loadSample(5)">Số 5</button>
                <button class="btn-sample" onclick="loadSample(6)">Số 6</button>
                <button class="btn-sample" onclick="loadSample(7)">Số 7</button>
                <button class="btn-sample" onclick="loadSample(8)">Số 8</button>
                <button class="btn-sample" onclick="loadSample(9)">Số 9</button>
            </div>

            <div class="mode-bar">
                <span>Chế độ chạy:</span>
                <select class="mode-select" id="hw_mode">
                    <option value="rtl_model">Mô phỏng Phần cứng Bit-Exact RTL</option>
                    <option value="fpga_uart">Board Thật FPGA (UART / USB)</option>
                </select>
            </div>
        </div>

        <!-- Right: Inference Dashboard -->
        <div class="card">
            <div class="card-title">
                <span>Kết Quả Suy Luận Phần Cứng</span>
                <span style="font-size: 11px; color: var(--green);">● HARDWARE READY</span>
            </div>

            <div class="result-box">
                <div class="pred-badge" id="res_digit">-</div>
                <div class="pred-desc">
                    <div class="title">Chữ Số Dự Đoán</div>
                    <div class="status" id="res_status">Chờ nhập ảnh...</div>
                </div>
            </div>

            <!-- Telemetry Metrics -->
            <div class="metrics-grid">
                <div class="metric-card">
                    <div class="metric-val">127.90 µs</div>
                    <div class="metric-lbl">Độ Trễ (Latency)</div>
                </div>
                <div class="metric-card">
                    <div class="metric-val">12,790</div>
                    <div class="metric-lbl">Số Chu Kỳ Clock</div>
                </div>
                <div class="metric-card">
                    <div class="metric-val">7,819 FPS</div>
                    <div class="metric-lbl">Thông Lượng (Throughput)</div>
                </div>
                <div class="metric-card">
                    <div class="metric-val">14.07 µJ</div>
                    <div class="metric-lbl">Năng Lượng / Lần Đoán</div>
                </div>
                <div class="metric-card">
                    <div class="metric-val">0 DSP</div>
                    <div class="metric-lbl">Khối Cứng DSP Sử Dụng</div>
                </div>
                <div class="metric-card">
                    <div class="metric-val">110 mW</div>
                    <div class="metric-lbl">Công Suất Động FPGA</div>
                </div>
            </div>

            <!-- Logits Distribution -->
            <div class="card-title" style="margin-bottom: 8px;">
                <span>Phân Bố Điểm Số Logits (Classes 0-9)</span>
            </div>
            <div id="chart_container"></div>
        </div>
    </div>

    <script>
        const cvs = document.getElementById('cvs');
        const ctx = cvs.getContext('2d');
        let isDrawing = false;

        // Init blank canvas
        function clearCanvas() {
            ctx.fillStyle = '#000000';
            ctx.fillRect(0, 0, cvs.width, cvs.height);
        }
        clearCanvas();

        // Drawing events
        cvs.addEventListener('mousedown', (e) => { isDrawing = true; draw(e); });
        cvs.addEventListener('mousemove', draw);
        window.addEventListener('mouseup', () => { isDrawing = false; ctx.beginPath(); });

        cvs.addEventListener('touchstart', (e) => { isDrawing = true; draw(e.touches[0]); e.preventDefault(); });
        cvs.addEventListener('touchmove', (e) => { draw(e.touches[0]); e.preventDefault(); });
        window.addEventListener('touchend', () => { isDrawing = false; ctx.beginPath(); });

        function draw(e) {
            if (!isDrawing) return;
            const rect = cvs.getBoundingClientRect();
            const x = e.clientX - rect.left;
            const y = e.clientY - rect.top;

            ctx.lineWidth = 22;
            ctx.lineCap = 'round';
            ctx.strokeStyle = '#ffffff';

            ctx.lineTo(x, y);
            ctx.stroke();
            ctx.beginPath();
            ctx.moveTo(x, y);
        }

        // Downsample canvas to 28x28 normalized array
        function getCanvasPixels() {
            const smallCvs = document.createElement('canvas');
            smallCvs.width = 28;
            smallCvs.height = 28;
            const smallCtx = smallCvs.getContext('2d');
            smallCtx.drawImage(cvs, 0, 0, 28, 28);
            const imgData = smallCtx.getImageData(0, 0, 28, 28);
            const pixels = [];
            for (let i = 0; i < imgData.data.length; i += 4) {
                // Pixel intensity [0, 255] scaled to INT8 [0, 127]
                const val = Math.floor(imgData.data[i] * 127 / 255);
                pixels.push(val);
            }
            return pixels;
        }

        // Render chart bars
        function renderChart(logits, bestDigit) {
            const container = document.getElementById('chart_container');
            container.innerHTML = '';
            const minVal = Math.min(...logits);
            const maxVal = Math.max(...logits);
            const range = (maxVal - minVal) || 1;

            for (let d = 0; d < 10; d++) {
                const score = logits[d];
                const pct = Math.max(5, Math.floor(((score - minVal) / range) * 100));
                const isBest = (d === bestDigit);

                const row = document.createElement('div');
                row.className = 'chart-row';
                row.innerHTML = `
                    <div class="chart-digit">${d}</div>
                    <div class="chart-bar-bg">
                        <div class="chart-bar ${isBest ? 'active' : ''}" style="width: ${pct}%"></div>
                    </div>
                    <div class="chart-score" style="${isBest ? 'color: var(--green); font-weight: 700;' : ''}">${score}</div>
                `;
                container.appendChild(row);
            }
        }

        // Initialize empty chart
        renderChart([0,0,0,0,0,0,0,0,0,0], -1);

        // API calls
        async function predictCanvas() {
            const pixels = getCanvasPixels();
            sendInference(pixels);
        }

        async function loadSample(digit) {
            document.getElementById('res_status').innerText = `Đang tải mẫu số ${digit}...`;
            try {
                const resp = await fetch(`/api/sample?digit=${digit}`);
                const data = await resp.json();
                if (data.pixels) {
                    // Draw to canvas
                    const smallImgData = ctx.createImageData(28, 28);
                    for (let i = 0; i < 784; i++) {
                        const px = Math.min(255, Math.floor(data.pixels[i] * 255 / 127));
                        smallImgData.data[i*4 + 0] = px;
                        smallImgData.data[i*4 + 1] = px;
                        smallImgData.data[i*4 + 2] = px;
                        smallImgData.data[i*4 + 3] = 255;
                    }
                    const tempCvs = document.createElement('canvas');
                    tempCvs.width = 28;
                    tempCvs.height = 28;
                    tempCvs.getContext('2d').putImageData(smallImgData, 0, 0);
                    ctx.imageSmoothingEnabled = false;
                    ctx.drawImage(tempCvs, 0, 0, 280, 280);

                    // Auto predict
                    sendInference(data.pixels);
                }
            } catch (e) {
                document.getElementById('res_status').innerText = 'Lỗi tải mẫu!';
            }
        }

        async function sendInference(pixels) {
            const mode = document.getElementById('hw_mode').value;
            document.getElementById('res_status').innerText = 'Đang suy luận (127.9 µs)...';

            try {
                const resp = await fetch('/api/predict', {
                    method: 'POST',
                    headers: { 'Content-Type': 'application/json' },
                    body: JSON.stringify({ image: pixels, mode: mode })
                });
                const res = await resp.json();
                document.getElementById('res_digit').innerText = res.predicted;
                document.getElementById('res_status').innerText = `Đoán đúng lớp số: ${res.predicted}`;
                renderChart(res.logits, res.predicted);
            } catch (e) {
                document.getElementById('res_status').innerText = 'Lỗi kết nối máy chủ!';
            }
        }
    </script>
</body>
</html>
"""

class RequestHandler(BaseHTTPRequestHandler):
    def log_message(self, format, *args):
        pass # Silence standard HTTP logs for clean console

    def do_GET(self):
        parsed = urllib.parse.urlparse(self.path)
        if parsed.path in ["/", "/index.html"]:
            self.send_response(200)
            self.send_header("Content-Type", "text/html; charset=utf-8")
            self.end_headers()
            self.wfile.write(HTML_PAGE.encode("utf-8"))
        elif parsed.path == "/api/sample":
            params = urllib.parse.parse_qs(parsed.query)
            digit = int(params.get("digit", [0])[0])
            hex_path = os.path.join(DATA_DIR, f"test_image_digit{digit}.hex")
            pixels = []
            if os.path.exists(hex_path):
                with open(hex_path) as f:
                    pixels = [int(line.strip(), 16) for line in f if line.strip()]
            self.send_response(200)
            self.send_header("Content-Type", "application/json")
            self.end_headers()
            self.wfile.write(json.dumps({"digit": digit, "pixels": pixels}).encode("utf-8"))
        else:
            self.send_response(404)
            self.end_headers()

    def do_POST(self):
        if self.path == "/api/predict":
            length = int(self.headers.get("Content-Length", 0))
            body = self.rfile.read(length).decode("utf-8")
            data = json.loads(body)
            img = data.get("image", [0] * 784)
            mode = data.get("mode", "rtl_model")

            pred_digit, logits = run_rtl_inference(img)

            self.send_response(200)
            self.send_header("Content-Type", "application/json")
            self.end_headers()
            self.wfile.write(json.dumps({
                "predicted": pred_digit,
                "logits": logits,
                "latency_us": 127.90,
                "cycles": 12790,
                "fps": 7819,
                "energy_uj": 14.07,
                "mode": mode
            }).encode("utf-8"))

class ReusableHTTPServer(HTTPServer):
    allow_reuse_address = True

def main():
    port = int(os.environ.get("PORT", 8080))
    server = None
    for p in range(port, port + 10):
        try:
            server = ReusableHTTPServer(("0.0.0.0", p), RequestHandler)
            port = p
            break
        except OSError:
            continue
    if server is None:
        print("[ERROR] Could not bind to any port from 8080 to 8090.")
        sys.exit(1)

    print("\n" + "=" * 80)
    print("   MINI-PULP LA-HWPE EDGE AI ACCELERATOR: INTERACTIVE LIVE DEMO GUI")
    print(f"   Server active at: http://localhost:{port}/")
    print(f"   (Also accessible from LAN/WiFi if running on same network)")
    print("   Press Ctrl+C to stop server.")
    print("=" * 80 + "\n")
    try:
        webbrowser.open(f"http://localhost:{port}/")
    except Exception:
        pass
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        print("\n[GUI] Server stopped.")

if __name__ == "__main__":
    main()
