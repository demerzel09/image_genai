#!/usr/bin/env bash
set -euo pipefail

# Run ComfyUI from project root, using /workspace/data as I/O
cd /workspace/ComfyUI

python3.12 main.py
