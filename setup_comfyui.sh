#!/bin/bash
set -e

# 非対話モードでタイムゾーンを設定
export DEBIAN_FRONTEND=noninteractive
ln -fs /usr/share/zoneinfo/Asia/Tokyo /etc/localtime
apt-get update
apt-get install -y tzdata
dpkg-reconfigure --frontend noninteractive tzdata


apt-get install -y \
    ffmpeg \
    libavformat-dev \
    libavcodec-dev \
    libavdevice-dev \
    libavutil-dev \
    libswscale-dev \
    libswresample-dev \
    libavfilter-dev \
    pkg-config \
    python3-dev



# 必要パッケージのインストール
apt-get install -y --no-install-recommends git curl ffmpeg \
    && rm -rf /var/lib/apt/lists/*

# ComfyUI clone（初回のみ）
if [ ! -d "ComfyUI/.git" ]; then
  echo "[*] Cloning ComfyUI ..."
  git clone https://github.com/comfyanonymous/ComfyUI.git ComfyUI
else
  echo "[*] ComfyUI already present. Skipping clone."
fi

# ComfyUI-Manager
if [ ! -d "ComfyUI/custom_nodes/ComfyUI-Manager" ]; then
    echo "--- ComfyUI-Manager クローン ---"
    git clone https://github.com/Comfy-Org/ComfyUI-Manager.git ComfyUI/custom_nodes/ComfyUI-Manager
else
    echo "--- ComfyUI-Manager 既存ディレクトリあり、スキップ ---"
fi

# ComfyUI-SAM2
if [ ! -d "ComfyUI/custom_nodes/ComfyUI-segment-anything-2" ]; then
    echo "--- ComfyUI-Segment-Anything-2 クローン ---"
    git clone https://github.com/kijai/ComfyUI-segment-anything-2.git ComfyUI/custom_nodes/ComfyUI-segment-anything-2
else
    echo "--- ComfyUI-Manager 既存ディレクトリあり、スキップ ---"
fi

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

# pipツール更新（壊れにくくする）
python -m pip install --upgrade --no-cache-dir "pip<25" setuptools wheel

# 1080 Ti / CUDA 11.8 用の制約ファイル
cat > /image_genai/constraints.txt <<EOF
numpy<2
opencv-python-headless==4.9.0.80
kornia==0.6.12
torch==2.1.2
torchvision==0.16.2
torchaudio==2.1.2
EOF

# ユーザの requirements.txt をインストール
if [ -f "/image_genai/requirements.txt" ]; then
  echo "[*] Installing requirements with constraints ..."
  pip install --no-cache-dir -c /image_genai/constraints.txt -r /image_genai/requirements.txt
else
  echo "[*] requirements.txt not found. Skipping deps."
fi

