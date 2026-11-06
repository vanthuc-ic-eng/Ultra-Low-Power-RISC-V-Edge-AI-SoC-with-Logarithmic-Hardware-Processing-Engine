#!/usr/bin/env bash
# ==============================================================================
# File: run_demo.sh
# Project: Mini-PULP Edge AI SoC (HCMUTE Edge AI Design Challenge)
# Description: One-click runner script for Interactive Live Demo Tool
# ==============================================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Text styling
BOLD='\033[1m'
CYAN='\033[0;36m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${CYAN}${BOLD}"
echo "================================================================================"
echo "   MINI-PULP LA-HWPE EDGE AI SOC : LIVE DEMO LAUNCHER"
echo "================================================================================"
echo -e "${NC}"

# Check Python3
if ! command -v python3 &> /dev/null; then
    echo -e "${YELLOW}[ERROR] python3 is not installed or not in PATH.${NC}"
    exit 1
fi

# Check numpy
if ! python3 -c "import numpy" &> /dev/null; then
    echo -e "${YELLOW}[!] Installing required dependency: numpy...${NC}"
    pip3 install numpy || python3 -m pip install numpy
fi

PORT="${PORT:-8080}"

echo -e "${GREEN}[+] Starting Web GUI Tool on Port ${PORT}...${NC}"
echo -e "${BOLD}--> Open your browser at: ${CYAN}http://localhost:${PORT}/${NC}"
echo -e "${BOLD}--> (Bấm Ctrl+C trong cửa sổ này để tắt tool khi dùng xong)${NC}"
echo ""

exec python3 sw/gui/app.py
