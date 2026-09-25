#!/usr/bin/env bash
# Runs on every codespace start. Idempotent.
set -euo pipefail

# No systemd in a codespace, so run the server ourselves.
pgrep -x ollama >/dev/null || {
  OLLAMA_HOST=0.0.0.0:11434 OLLAMA_KEEP_ALIVE=1h \
    nohup ollama serve > /tmp/ollama.log 2>&1 &
}

until curl -sf http://localhost:11434/ >/dev/null; do sleep 1; done

docker start open-webui 2>/dev/null || \
  docker run -d --name open-webui --network=host --restart unless-stopped \
    -e OLLAMA_BASE_URL=http://localhost:11434 \
    -e WEBUI_AUTH=False \
    -e PORT=8080 \
    -v open-webui:/app/backend/data \
    ghcr.io/open-webui/open-webui:main

echo "Ollama: http://localhost:11434   Open WebUI: http://localhost:8080"
