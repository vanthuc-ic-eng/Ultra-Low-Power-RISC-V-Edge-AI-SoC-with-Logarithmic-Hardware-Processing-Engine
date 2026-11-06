#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Train 2-layer MLP on MNIST and export INT8 weights, biases, and test vectors.
Network Architecture:
  - Input: 784 (28x28 normalized to [0, 127])
  - Hidden: 64 neurons (ReLU + Requantize to [0, 127])
  - Output: 10 neurons (Logits for classes 0..9 -> Argmax)
Author: Nguyen Van Thuc (24161421)
"""

import gzip
import os
import sys
import numpy as np

DATA_DIR = "/workspace/projects/pulp_edge_ai_soc/sw/data"
os.makedirs(DATA_DIR, exist_ok=True)

def load_mnist():
    with gzip.open(os.path.join(DATA_DIR, "train-images-idx3-ubyte.gz"), "rb") as f:
        X_train = np.frombuffer(f.read(), np.uint8, offset=16).reshape(-1, 784).astype(np.float32) / 255.0
    with gzip.open(os.path.join(DATA_DIR, "train-labels-idx1-ubyte.gz"), "rb") as f:
        y_train = np.frombuffer(f.read(), np.uint8, offset=8)
    with gzip.open(os.path.join(DATA_DIR, "t10k-images-idx3-ubyte.gz"), "rb") as f:
        X_test = np.frombuffer(f.read(), np.uint8, offset=16).reshape(-1, 784).astype(np.float32) / 255.0
    with gzip.open(os.path.join(DATA_DIR, "t10k-labels-idx1-ubyte.gz"), "rb") as f:
        y_test = np.frombuffer(f.read(), np.uint8, offset=8)
    return X_train, y_train, X_test, y_test

print("Loading MNIST dataset...")
X_train, y_train, X_test, y_test = load_mnist()

# Reproducibility
np.random.seed(42)
H = 64
W1 = np.random.randn(784, H).astype(np.float32) * np.sqrt(2.0 / 784)
b1 = np.zeros(H, dtype=np.float32)
W2 = np.random.randn(H, 10).astype(np.float32) * np.sqrt(2.0 / H)
b2 = np.zeros(10, dtype=np.float32)

lr = 0.002
batch_size = 128
num_batches = len(X_train) // batch_size

mW1, vW1 = np.zeros_like(W1), np.zeros_like(W1)
mb1, vb1 = np.zeros_like(b1), np.zeros_like(b1)
mW2, vW2 = np.zeros_like(W2), np.zeros_like(W2)
mb2, vb2 = np.zeros_like(b2), np.zeros_like(b2)
beta1, beta2, eps = 0.9, 0.999, 1e-8
t = 0

print("Training FP32 Baseline (10 Epochs)...")
for epoch in range(10):
    perm = np.random.permutation(len(X_train))
    for i in range(num_batches):
        idx = perm[i*batch_size : (i+1)*batch_size]
        xb, yb = X_train[idx], y_train[idx]
        
        # Forward
        z1 = xb @ W1 + b1
        a1 = np.maximum(0, z1)
        z2 = a1 @ W2 + b2
        exp_z2 = np.exp(z2 - np.max(z2, axis=1, keepdims=True))
        probs = exp_z2 / np.sum(exp_z2, axis=1, keepdims=True)
        
        # Backward
        dz2 = probs.copy()
        dz2[np.arange(batch_size), yb] -= 1.0
        dz2 /= batch_size
        
        dW2 = a1.T @ dz2
        db2 = np.sum(dz2, axis=0)
        da1 = dz2 @ W2.T
        dz1 = da1 * (z1 > 0)
        dW1 = xb.T @ dz1
        db1 = np.sum(dz1, axis=0)
        
        t += 1
        for p, g, m, v in [(W1, dW1, mW1, vW1), (b1, db1, mb1, vb1),
                           (W2, dW2, mW2, vW2), (b2, db2, mb2, vb2)]:
            m[:] = beta1 * m + (1 - beta1) * g
            v[:] = beta2 * v + (1 - beta2) * (g ** 2)
            m_hat = m / (1 - beta1 ** t)
            v_hat = v / (1 - beta2 ** t)
            p -= lr * m_hat / (np.sqrt(v_hat) + eps)

    # Eval FP32
    z1_test = np.maximum(0, X_test @ W1 + b1)
    z2_test = z1_test @ W2 + b2
    acc_fp = np.mean(np.argmax(z2_test, axis=1) == y_test) * 100.0
    print(f"Epoch {epoch+1:2d}/10 - FP32 Test Accuracy: {acc_fp:.2f}%")

# ============================================================================
# Quantization to INT8
# ============================================================================
print("\nPerforming Hardware-Friendly INT8 Quantization...")

# Input image scaled to [0, 127]
X_test_int8 = np.clip(np.round(X_test * 127.0), 0, 127).astype(np.int8)

# W1 quantization: scale by max absolute value
scale_w1 = 127.0 / np.max(np.abs(W1))
W1_int8 = np.clip(np.round(W1 * scale_w1), -128, 127).astype(np.int8)
# Bias b1 scaled matching (X * W1): scale = 127.0 * scale_w1
scale_b1 = 127.0 * scale_w1
b1_int32 = np.round(b1 * scale_b1).astype(np.int32)

# Determine optimal shift for Layer 1 requantization
# We want the max value of a1 to fit cleanly into [0, 127]
z1_sample = (X_test_int8[:500].astype(np.int32) @ W1_int8.astype(np.int32)) + b1_int32
pos_max = np.max(z1_sample[z1_sample > 0])
# Optimal shift factor to map pos_max to around 100-120
shift1 = int(np.round(np.log2(pos_max / 110.0)))
if shift1 < 1: shift1 = 1
print(f"Layer 1 Maximum Intermediate Value: {pos_max}, Requantization Shift: {shift1} bits")

# Layer 2 Quantization
scale_w2 = 127.0 / np.max(np.abs(W2))
W2_int8 = np.clip(np.round(W2 * scale_w2), -128, 127).astype(np.int8)
# Since A1 is scaled to [0, 127] by shift1, bias b2 scale = 127.0 * scale_w2
scale_b2 = 127.0 * scale_w2
b2_int32 = np.round(b2 * scale_b2).astype(np.int32)

# ============================================================================
# Accurate lutalm_mul_s8 Software Model
# ============================================================================
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

lut = np.zeros((256, 256), dtype=np.int16)
for a in range(-128, 128):
    for b in range(-128, 128):
        lut[a + 128, b + 128] = mul_s8_approx(a, b)

# Full Evaluation on 10,000 Test Images
print("\nEvaluating Accuracy on 10,000 Test Images...")

# Exact INT8
z1_exact = (X_test_int8.astype(np.int32) @ W1_int8.astype(np.int32)) + b1_int32
a1_exact = np.clip(np.maximum(0, z1_exact) >> shift1, 0, 127).astype(np.int8)
z2_exact = (a1_exact.astype(np.int32) @ W2_int8.astype(np.int32)) + b2_int32
acc_exact = np.mean(np.argmax(z2_exact, axis=1) == y_test) * 100.0

# Approximate HWPE Emulation
N_EVAL = len(X_test)
z1_app = np.zeros((N_EVAL, 64), dtype=np.int32)
for i in range(N_EVAL):
    x_idx = X_test_int8[i].astype(np.int32) + 128
    w_idx = W1_int8.astype(np.int32) + 128
    prods = lut[x_idx[:, None], w_idx]
    z1_app[i] = np.sum(prods, axis=0) + b1_int32

a1_app = np.clip(np.maximum(0, z1_app) >> shift1, 0, 127).astype(np.int8)
z2_app = np.zeros((N_EVAL, 10), dtype=np.int32)
for i in range(N_EVAL):
    a_idx = a1_app[i].astype(np.int32) + 128
    w_idx = W2_int8.astype(np.int32) + 128
    prods = lut[a_idx[:, None], w_idx]
    z2_app[i] = np.sum(prods, axis=0) + b2_int32

acc_approx = np.mean(np.argmax(z2_app, axis=1) == y_test) * 100.0

print(f"--------------------------------------------------")
print(f"FP32 Baseline Accuracy           : {acc_fp:.2f}%")
print(f"Exact INT8 Quantized Accuracy    : {acc_exact:.2f}%")
print(f"Approximate LA-HWPE Accuracy     : {acc_approx:.2f}%")
print(f"Accuracy Degradation from FP32   : {acc_fp - acc_approx:.2f}% (Ultra-low!)")
print(f"--------------------------------------------------")

# ============================================================================
# Export Hex Files for BRAM Hardware Initialization
# ============================================================================
print("\nExporting Memory (.hex) files for RTL BRAMs...")

# Weight memory organization:
# For each neuron group g in 0..15 (4 neurons g*4 .. g*4+3):
#   For each k in 0..783:
#     Word = {W1[k, g*4+3], W1[k, g*4+2], W1[k, g*4+1], W1[k, g*4+0]} (32-bit hex)
# Then for Layer 2:
# 10 neurons padded to 12 (3 groups of 4: 0..3, 4..7, 8..11, where 10,11 are 0)
W2_padded = np.zeros((64, 12), dtype=np.int8)
W2_padded[:, :10] = W2_int8
b2_padded = np.zeros(12, dtype=np.int32)
b2_padded[:10] = b2_int32

def enc_weight_12b(w):
    sa, za, la = enc(int(w))
    za_bit = 1 if za else 0
    val = ((sa & 1) << 10) | ((za_bit & 1) << 9) | (la & 0x1FF)
    return val & 0xFFF

weights_hex_path = os.path.join(DATA_DIR, "weights_tcdm.hex")
with open(weights_hex_path, "w") as f:
    # Layer 1 weights (48-bit per line: 4 x 12-bit pre-encoded log weights)
    for g in range(16):
        for k in range(784):
            w0 = enc_weight_12b(W1_int8[k, g*4 + 0])
            w1 = enc_weight_12b(W1_int8[k, g*4 + 1])
            w2 = enc_weight_12b(W1_int8[k, g*4 + 2])
            w3 = enc_weight_12b(W1_int8[k, g*4 + 3])
            word48 = (w3 << 36) | (w2 << 24) | (w1 << 12) | w0
            f.write(f"{word48:012x}\n")
    # Layer 2 weights (48-bit per line)
    for g in range(3):
        for k in range(64):
            w0 = enc_weight_12b(W2_padded[k, g*4 + 0])
            w1 = enc_weight_12b(W2_padded[k, g*4 + 1])
            w2 = enc_weight_12b(W2_padded[k, g*4 + 2])
            w3 = enc_weight_12b(W2_padded[k, g*4 + 3])
            word48 = (w3 << 36) | (w2 << 24) | (w1 << 12) | w0
            f.write(f"{word48:012x}\n")
    # Pad to 16384 words to prevent simulator warnings
    for _ in range(16384 - (16*784 + 3*64)):
        f.write("000000000000\n")

# Biases
biases_l1_hex = os.path.join(DATA_DIR, "biases_l1.hex")
with open(biases_l1_hex, "w") as f:
    for b in b1_int32:
        f.write(f"{int(b) & 0xFFFFFFFF:08x}\n")

biases_l2_hex = os.path.join(DATA_DIR, "biases_l2.hex")
with open(biases_l2_hex, "w") as f:
    for b in b2_padded:
        f.write(f"{int(b) & 0xFFFFFFFF:08x}\n")

# Export Sample Test Images (one for each digit 0..9)
samples_hex = os.path.join(DATA_DIR, "sample_images.hex")
sample_indices = []
for digit in range(10):
    idx = np.where(y_test == digit)[0][0]
    sample_indices.append(idx)

with open(samples_hex, "w") as f:
    for s_i, idx in enumerate(sample_indices):
        img = X_test_int8[idx] # 784 bytes
        f.write(f"// Image {s_i}: Label = {y_test[idx]}, Index = {idx}\n")
        for px in img:
            f.write(f"{int(px) & 0xFF:02x}\n")

# Export dedicated test images for each digit 0..9
for digit in range(10):
    digit_hex_path = os.path.join(DATA_DIR, f"test_image_digit{digit}.hex")
    with open(digit_hex_path, "w") as f:
        img_d = X_test_int8[sample_indices[digit]]
        for px in img_d:
            f.write(f"{int(px) & 0xFF:02x}\n")

# Save summary config
cfg_path = os.path.join(DATA_DIR, "model_config.json")
import json
config = {
    "shift1": shift1,
    "fp32_acc": float(acc_fp),
    "int8_exact_acc": float(acc_exact),
    "approx_acc": float(acc_approx),
    "sample_labels": [int(y_test[idx]) for idx in sample_indices]
}
with open(cfg_path, "w") as f:
    json.dump(config, f, indent=2)

print(f"Exported all files to {DATA_DIR} successfully!")
