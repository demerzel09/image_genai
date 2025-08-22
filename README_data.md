ComfyUI data mapping (host <-> container)

- Host: ./data
  - ./data/input   -> Container: /workspace/data/input
  - ./data/output  -> Container: /workspace/data/output
  - ./data/user    -> Container: /workspace/data/user
  - ./data/temp    -> Container: /workspace/data/temp

Usage examples

1) Initialize directories
   ./comfy_local.sh init-dirs

2) Put assets into input
   ./comfy_local.sh ingest /path/to/assets

3) Start ComfyUI server in the running container on :8190
   ./comfy_local.sh start

4) Tail logs
   ./comfy_local.sh logs

5) Export generated images
   ./comfy_local.sh export /path/to/save

Env overrides

- CONTAINER=image_genai_app
- PORT=8190
- COMFY_ARGS="--highvram --preview-method taesd"
