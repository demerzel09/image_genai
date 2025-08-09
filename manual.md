了解です。
**「LinuxリモートPCにVS Code Remote-SSHで接続 → PyTorch GPU対応Dockerコンテナ → Dev Containerで接続」**
という **GPU活用の王道手順**を、Linux側とWindows側に分けてマニュアル化します。
実験用の最小構成も付けます。

---

## 1. 全体構成イメージ

* **Windows側**

  * VS Code
  * Remote - SSH / Dev Containers 拡張
  * SSHでリモートLinuxに接続

* **Linuxリモート側**

  * NVIDIA GPU ＆ ドライバ
  * NVIDIA Container Toolkit
  * Docker / Docker Compose
  * PyTorch GPU対応イメージで Dev Container を構築

---

## 2. LinuxリモートPC側 準備マニュアル

### 2.1 NVIDIA ドライバ確認 / インストール

```bash
nvidia-smi
```

* 正常に表示されればOK
* 出ない場合 → OSとGPUに対応したドライバをNVIDIA公式からインストール

---

### 2.2 Docker & Compose プラグイン

```bash
curl -fsSL https://get.docker.com | sudo sh
sudo usermod -aG docker $USER
newgrp docker
docker run --rm hello-world
```

---

### 2.3 NVIDIA Container Toolkit

公式手順（[https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/install-guide.html）に従って導入：](https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/install-guide.html）に従って導入：)

```bash
# リポジトリ追加
distribution=$(. /etc/os-release;echo $ID$VERSION_ID)
curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey | sudo gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit.gpg
curl -s -L https://nvidia.github.io/libnvidia-container/$distribution/libnvidia-container.list |
  sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit.gpg] https://#g' |
  sudo tee /etc/apt/sources.list.d/nvidia-container-toolkit.list

# インストール
sudo apt-get update
sudo apt-get install -y nvidia-container-toolkit

# 設定反映
sudo nvidia-ctk runtime configure --runtime=docker
sudo systemctl restart docker
```

---

### 2.4 動作確認（GPU可視化）

```bash
docker run --rm --gpus all nvidia/cuda:12.2.0-base-ubuntu22.04 nvidia-smi
```

→ GPU一覧が表示されればOK

---

### 2.5 プロジェクト構成（リモート側）

```bash
mkdir -p ~/projects/pytorch-gpu/.devcontainer
cd ~/projects/pytorch-gpu
```

#### `.devcontainer/docker-compose.yml`

```yaml
services:
  dev:
    image: pytorch/pytorch:2.4.0-cuda12.1-cudnn8-devel
    container_name: pytorch-gpu-dev
    command: sleep infinity
    tty: true
    environment:
      - TZ=Asia/Tokyo
    deploy:
      resources:
        reservations:
          devices:
            - capabilities: ["gpu"]
    volumes:
      - ..:/workspaces:cached
```

#### `.devcontainer/devcontainer.json`

```json
{
  "name": "pytorch-gpu-dev",
  "dockerComposeFile": "docker-compose.yml",
  "service": "dev",
  "workspaceFolder": "/workspaces/${localWorkspaceFolderBasename}",
  "remoteUser": "root",
  "features": {
    "ghcr.io/devcontainers/features/common-utils:2": {}
  },
  "customizations": {
    "vscode": {
      "extensions": [
        "ms-python.python",
        "ms-toolsai.jupyter"
      ]
    }
  }
}
```

---

### 2.6 コンテナでGPU動作テスト

Dev Containerに入ったら：

```python
import torch
print(torch.cuda.is_available())  # True ならOK
print(torch.cuda.get_device_name(0))
```

---

## 3. Windows側 準備マニュアル

### 3.1 VS Code インストール

* [https://code.visualstudio.com/](https://code.visualstudio.com/) から最新版をインストール

### 3.2 拡張機能の導入

* **Remote - SSH**
* **Dev Containers**
* （Python開発時）**Python** / **Jupyter**

---

### 3.3 SSH設定

* PowerShell または Windows Terminal で接続確認：

```powershell
ssh <user>@<remote-host>
```

* 鍵認証を推奨（`ssh-keygen` → `~/.ssh/authorized_keys`に公開鍵登録）

---

### 3.4 Remote-SSH で接続

1. VS Code 左下の「><」→ **Remote-SSH: Connect to Host…**
2. リモートLinuxに接続
3. 初回はVS Code Serverのインストール待ち

---

### 3.5 プロジェクトを開いて Dev Container 起動

1. 接続後、`~/projects/pytorch-gpu` を開く
2. 右下のポップアップ or `Ctrl+Shift+P` → **Reopen in Container**
3. コンテナが起動し、GPUを使ったPyTorch開発が可能に

---

## 4. 運用のポイント

* **nvidia-smiがDev Container内で動く**ことを必ず確認
* コンテナを落とすとき：

```bash
docker compose down
```

* CUDA/PyTorchのバージョンはプロジェクト要件に合わせて `pytorch/pytorch` イメージタグを変更
* 複数人で同じ環境を再現する場合、この `.devcontainer` ディレクトリごとGit管理すると便利

---

この構成は**GPUパワーを最大限活用しつつ、VS Codeからシームレスに開発**できる「王道」です。
もし希望あれば、この上に**webtopやGUIツールを追加したGPU対応構成**も作れます。

このマニュアル、最終的に図解付きでまとめたPDF化もできますがどうしますか？
