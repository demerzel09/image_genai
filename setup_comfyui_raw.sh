#!/usr/bin/env bash
set -e

# カレントを image_genai に移動（compose.ymlがここにある想定）
cd "$(dirname "$0")"

echo "=== ComfyUI セットアップ開始 ==="

# ComfyUI 本体
if [ ! -d "ComfyUI" ]; then
    echo "--- ComfyUI クローン ---"
    git clone https://github.com/comfyanonymous/ComfyUI.git
else
    echo "--- ComfyUI 既存ディレクトリあり、スキップ ---"
fi

# ComfyUI-Manager
if [ ! -d "ComfyUI/custom_nodes/ComfyUI-Manager" ]; then
    echo "--- ComfyUI-Manager クローン ---"
    git clone https://github.com/Comfy-Org/ComfyUI-Manager.git ComfyUI/custom_nodes/ComfyUI-Manager
else
    echo "--- ComfyUI-Manager 既存ディレクトリあり、スキップ ---"
fi

# Python依存パッケージ（ComfyUIの推奨requirementsに加えてSAM2用も）
echo "--- Pythonパッケージインストール ---"
pip install --upgrade pip
pip install -r ComfyUI/requirements.txt


echo "=== セットアップ完了 ==="
