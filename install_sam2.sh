#!/usr/bin/env bash
set -e

# ComfyUI のカスタムノードディレクトリへ移動
cd "$(dirname "$0")"
CUSTOM_NODE_DIR="ComfyUI/custom_nodes"
mkdir -p "$CUSTOM_NODE_DIR"

echo "=== Clone ComfyUI-segment-anything-2 ==="
if [ ! -d "$CUSTOM_NODE_DIR/ComfyUI-segment-anything-2" ]; then
    git clone https://github.com/kijai/ComfyUI-segment-anything-2.git \
        "$CUSTOM_NODE_DIR/ComfyUI-segment-anything-2"
else
    echo "--- 既に存在します、スキップ ---"
fi

echo "=== Install Python dependencies ==="
# 依存をインストール（既存のPyTorch環境を壊さないよう --no-deps）
REQ_FILE="$CUSTOM_NODE_DIR/ComfyUI-segment-anything-2/requirements.txt"
if [ -f "$REQ_FILE" ]; then
    pip install --no-cache-dir -r "$REQ_FILE" --no-deps
fi

# Kornia バージョン不整合回避（必要に応じて）
pip install --no-cache-dir "kornia==0.6.12"

echo "=== Prepare SAM2 model directory ==="
MODEL_DIR="ComfyUI/models/sam2"
mkdir -p "$MODEL_DIR"

echo "=== Download SAM2 weights from HuggingFace ==="
HF_URL="https://huggingface.co/facebook/sam2-hiera-large/resolve/main/sam2_hiera_large.pt"
TARGET="$MODEL_DIR/sam2_hiera_large.pt"
if [ ! -f "$TARGET" ]; then
    curl -L "$HF_URL" -o "$TARGET"
else
    echo "--- 既にモデルがあります、スキップ ---"
fi

echo "=== Installation complete ==="
echo "ComfyUI を再起動してください。"
