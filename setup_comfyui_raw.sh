#!/usr/bin/env bash
# ============================================
# ComfyUI setup (idempotent)
# - Ubuntu 22.04 + CUDA 12.8 想定
# - Python 3.12 を導入して以降は 3.12 環境に統一
# - 初回のみ重処理（APT / Python 導入など）
# - 2回目以降は軽処理＆更新だけ
# ============================================

set -euo pipefail
trap 'echo "[ERROR] line:$LINENO status:$?" >&2' ERR

export DEBIAN_FRONTEND=noninteractive
: "${TZ:=Asia/Tokyo}"                 # タイムゾーン（必要に応じて変更）
: "${PYTHON_BIN:=python3.12}"         # 以降の Python は 3.12 を想定
: "${USE_FLASH_ATTN:=0}"              # 1 にすると flash-attn を導入（要 devel イメージ）
: "${COMFY_REPO:=https://github.com/comfyanonymous/ComfyUI.git}"
: "${COMFY_DIR:=ComfyUI}"
: "${COMFY_MGR_REPO:=https://github.com/Comfy-Org/ComfyUI-Manager.git}"
: "${COMFY_MGR_DIR:=ComfyUI/custom_nodes/ComfyUI-Manager}"
: "${INIT_MARKER:=/var/lib/comfyui/.initialized}"
# CUDA 12.8 の PyTorch wheel 用 index（別版は cu121, cu122 などに置換）
: "${TORCH_INDEX_URL:=https://download.pytorch.org/whl/cu128}"

export PIP_ROOT_USER_ACTION=ignore

# このスクリプトが置かれているディレクトリを作業ディレクトリに
cd "$(dirname "$0")"

# ---------------------------
# helper functions
# ---------------------------
ensure_python312() {
  if ! command -v python3.12 >/dev/null 2>&1; then
    echo ">>> Installing Python 3.12"
    apt_update_safe
    apt_install_safe software-properties-common ca-certificates gnupg
    add-apt-repository -y ppa:deadsnakes/ppa
    apt_update_safe
    apt_install_safe python3.12 python3.12-venv python3.12-dev
    python3.12 -m ensurepip --upgrade
    python3.12 -m pip install --upgrade pip setuptools wheel
  fi
}

apt_update_safe() {
  # APT キャッシュが消えている可能性もあるので都度 update
  apt-get update -y
}

apt_install_safe() {
  # 既に入っているパッケージがあっても OK（何度実行しても良い）
  apt-get install -y --no-install-recommends "$@"
}

git_clone_or_pull() {
  local repo="$1" dst="$2"
  if [[ -d "$dst/.git" ]]; then
    git -C "$dst" fetch --all --tags --prune
    git -C "$dst" pull --rebase --autostash
  else
    git clone --depth 1 "$repo" "$dst"
  fi
}

ensure_timezone() {
  ln -fs "/usr/share/zoneinfo/$TZ" /etc/localtime
  dpkg-reconfigure --frontend noninteractive tzdata || true
}

# ---------------------------
# 初回のみ実行したい重処理
# ---------------------------
if [[ ! -f "$INIT_MARKER" ]]; then
  mkdir -p "$(dirname "$INIT_MARKER")"

  ensure_timezone
  apt_update_safe

  # 基本ツール
  apt_install_safe \
    tzdata ca-certificates gnupg lsb-release \
    curl wget git ffmpeg \
    build-essential pkg-config

  # deadsnakes PPA（Ubuntu 22.04 で python3.12 を使う）
  apt_install_safe software-properties-common
  add-apt-repository -y ppa:deadsnakes/ppa
  apt_update_safe

  # Python 3.12 一式
  apt_install_safe python3.12 python3.12-venv python3.12-dev

  # APT キャッシュ削減（レイヤを軽く）
  rm -rf /var/lib/apt/lists/*

  touch "$INIT_MARKER"
fi

echo "=== Repos ==="
# ComfyUI 本体と Manager を配置（存在すれば更新）
git_clone_or_pull "$COMFY_REPO" "$COMFY_DIR"
mkdir -p "$(dirname "$COMFY_MGR_DIR")"
git_clone_or_pull "$COMFY_MGR_REPO" "$COMFY_MGR_DIR"

# ---------------------------
# Python 依存（常に 3.12 へ入れる）
# ---------------------------
# まず現在の torch を確認（存在しない場合のみ入る想定でも良いが、ここでは明示固定）
ensure_python312
echo "=== PyTorch (CUDA 12.8 wheel) ==="
${PYTHON_BIN} -m pip install --index-url "${TORCH_INDEX_URL}" \
  torch torchvision torchaudio

# ComfyUI の requirements（torch を上書きしないよう index 先は上で固定）
echo "=== ComfyUI requirements ==="
${PYTHON_BIN} -m pip install --no-cache-dir -r "${COMFY_DIR}/requirements.txt" || true

# ComfyUI-Manager の requirements
echo "=== ComfyUI-Manager requirements ==="
if [[ -f "${COMFY_MGR_DIR}/requirements.txt" ]]; then
  ${PYTHON_BIN} -m pip install --no-cache-dir -r "${COMFY_MGR_DIR}/requirements.txt" || true
fi

# 必須だが requirements に入っていないもの
${PYTHON_BIN} -m pip install --no-cache-dir pyyaml

# （任意）flash-attn の導入
# - wheel があればそのまま入る
# - wheel が無い場合、--no-build-isolation でビルド（devel イメージ推奨）
if [[ "${USE_FLASH_ATTN}" == "1" ]]; then
  echo "=== Installing flash-attn (optional) ==="
  ${PYTHON_BIN} -m pip install --no-cache-dir --no-build-isolation flash-attn || \
  { echo "[warn] flash-attn install failed; continuing without it"; true; }
else
  # 使わない場合は入っていたら削除（未定義シンボル対策）
  ${PYTHON_BIN} -m pip uninstall -y flash-attn flash_attn >/dev/null 2>&1 || true
fi

# 動作確認のための情報出力
echo "=== Environment summary ==="
${PYTHON_BIN} - <<'PY'
import sys, importlib
print("python", sys.version.split()[0])
try:
  import torch
  print("torch", torch.__version__, "cuda", getattr(torch.version, "cuda", None))
except Exception as e:
  print("torch import error:", e)
print("flash_attn present?", importlib.util.find_spec("flash_attn") is not None)
PY

echo "=== Setup completed ==="
