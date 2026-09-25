#!/usr/bin/env bash
# GLM-4.5-Air (106B-A12B) at IQ3_XXS on CPU, via llama.cpp.
# 50.3 GB of weights in two shards + KV cache. Needs the 64 GB machine.
set -euo pipefail

MODEL_REPO=bartowski/zai-org_GLM-4.5-Air-GGUF
QUANT=IQ3_XXS
CTX=${CTX:-8192}
PORT=8081

# Free the RAM Ollama is sitting on: 50 GB of weights leaves no room for a
# resident 14 GB gpt-oss. ponytail: unload, don't uninstall.
command -v ollama >/dev/null && ollama stop gpt-oss:20b 2>/dev/null || true

if [ ! -x ~/llama.cpp/build/bin/llama-server ]; then
  sudo apt-get update -qq && sudo apt-get install -y -qq cmake libcurl4-openssl-dev
  git clone --depth 1 https://github.com/ggml-org/llama.cpp ~/llama.cpp
  cmake -S ~/llama.cpp -B ~/llama.cpp/build -DCMAKE_BUILD_TYPE=Release -DLLAMA_CURL=ON
  cmake --build ~/llama.cpp/build --target llama-server -j "$(nproc)"
fi

# -hf pulls both shards and caches them in ~/.cache/llama.cpp (~50 GB, one time).
# mmap is on by default: pages are faulted in as needed rather than read up front,
# so startup is fast and the page cache absorbs the rest.
exec ~/llama.cpp/build/bin/llama-server \
  -hf "${MODEL_REPO}:${QUANT}" \
  -c "$CTX" \
  -t "$(nproc)" \
  --host 0.0.0.0 --port "$PORT"
