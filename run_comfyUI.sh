#!/usr/bin/env bash
set -euo pipefail

# Run ComfyUI from project root, using /workspace/data as I/O
cd /workspace/ComfyUI

mkdir -p /workspace/data/input /workspace/data/output /workspace/data/user /workspace/data/temp

exec python3.12 main.py \
  --listen 0.0.0.0 \
  --port 8190 \
  --input-directory /workspace/data/input \
  --output-directory /workspace/data/output \
  --user-directory /workspace/data/user \
  --temp-directory /workspace/data/temp \
  "$@"
