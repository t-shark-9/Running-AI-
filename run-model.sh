#!/usr/bin/env bash
# Biggest open-weights model that fits 64 GB of RAM, on CPU, via llama.cpp.
#
# Default: Qwen3.5-122B-A10B at UD-IQ3_S (46.6 GB, 10B active params).
# Override:  REPO=... QUANT=... ./run-model.sh
# Known-good alternatives:
#   REPO=bartowski/zai-org_GLM-4.5-Air-GGUF   QUANT=IQ3_XXS   (50.3 GB)
#   REPO=unsloth/Qwen3.6-35B-A3B-GGUF         QUANT=Q8_0      (36.9 GB, much faster)
set -euo pipefail

REPO=${REPO:-unsloth/Qwen3.5-122B-A10B-GGUF}
QUANT=${QUANT:-UD-IQ3_S}
CTX=${CTX:-8192}
PORT=${PORT:-8081}

# 46.6 GB of weights leaves no room for a resident 14 GB gpt-oss.
# ponytail: unload, don't uninstall.
command -v ollama >/dev/null && ollama stop gpt-oss:20b 2>/dev/null || true

if [ ! -x ~/llama.cpp/build/bin/llama-server ]; then
  sudo apt-get update -qq && sudo apt-get install -y -qq cmake libcurl4-openssl-dev
  git clone --depth 1 https://github.com/ggml-org/llama.cpp ~/llama.cpp
  cmake -S ~/llama.cpp -B ~/llama.cpp/build -DCMAKE_BUILD_TYPE=Release -DLLAMA_CURL=ON
  cmake --build ~/llama.cpp/build --target llama-server -j "$(nproc)"
fi

df -h / | tail -1   # 128 GB total; the download needs ~47 GB of it

# mmap is on by default: pages fault in as needed, so startup is fast and the
# page cache absorbs the rest. Weights still all end up resident.
exec ~/llama.cpp/build/bin/llama-server \
  -hf "${REPO}:${QUANT}" \
  -c "$CTX" \
  -t "$(nproc)" \
  --host 0.0.0.0 --port "$PORT"
