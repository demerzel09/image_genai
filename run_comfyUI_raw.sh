#!/usr/bin/env bash
# Raw launcher: run ComfyUI with its defaults (ComfyUI/ directories)
cd /workspace/ComfyUI
exec python3.12 main.py "$@"