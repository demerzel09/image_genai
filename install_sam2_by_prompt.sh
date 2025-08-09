#!/usr/bin/env bash
set -e

# ComfyUI のカスタムノードディレクトリへ移動
cd "$(dirname "$0")"
CUSTOM_NODE_DIR="ComfyUI/custom_nodes"
mkdir -p "$CUSTOM_NODE_DIR"

# ComfyUI-SAM2
if [ ! -d "ComfyUI/custom_nodes/ComfyUI-SAM2" ]; then
    echo "--- ComfyUI-SAM2 クローン ---"
    git clone https://github.com/neverbiasu/ComfyUI-SAM2.git ComfyUI/custom_nodes/ComfyUI-SAM2
else
    echo "--- ComfyUI-SAM2 既存ディレクトリあり、スキップ ---"
fi

echo "=== Install Python dependencies ==="
# 依存をインストール（既存のPyTorch環境を壊さないよう --no-deps）
REQ_FILE="$CUSTOM_NODE_DIR/ComfyUI-SAM2/requirements.txt"
if [ -f "$REQ_FILE" ]; then
    pip install --no-cache-dir -r "$REQ_FILE" --no-deps
fi

# Kornia バージョン不整合回避（必要に応じて）
pip install --no-cache-dir "kornia==0.6.12"

# モデル保存先
echo "=== Prepare SAM2 model directory ==="
MODEL_DIR="ComfyUI/models/sam2"
mkdir -p "$MODEL_DIR"

# SAM2モデルのダウンロード（facebook/sam2-hiera-large）
echo "--- SAM2 モデルダウンロード ---"
HF_URL="https://huggingface.co/facebook/sam2-hiera-large/resolve/main/sam2_hiera_large.pt"
if [ ! -f "$MODEL_DIR/sam2_hiera_large.pt" ]; then
    curl -L "$HF_URL" -o "$MODEL_DIR/sam2_hiera_large.pt"
else
    echo "--- sam2_hiera_large.pt 既存ファイルあり、スキップ ---"
fi

echo "=== Installation complete ==="
echo "ComfyUI を再起動してください。"
