#!/usr/bin/env bash
# DiffusionGemma-26B-A4B on CPU, interactive chat.
#
# This is a block-diffusion model, not autoregressive: it denoises a whole
# 256-token canvas at once instead of emitting left to right.
#
# Upstream llama.cpp does NOT support it. Its diffusion code covers Dream,
# LLaDA and LLaDA-MoE only, and the GGUF declares general.architecture =
# "diffusion-gemma", which upstream rejects. Support lives in an unmerged PR.
#
# Two PRs add it. #24427 builds but segfaults while loading tensors.
# #24423 works. ponytail: pinned to the one that runs, not the newest.
set -euo pipefail

PR=24423
QUANT=${QUANT:-BF16}   # BF16 50.5 GB (biggest that fits 64 GB) | Q8_0 26.9 | Q4_K_M 16.8
REPO=unsloth/diffusiongemma-26B-A4B-it-GGUF

if [ ! -x ~/llama.cpp/build/bin/llama-diffusion-cli ]; then
  sudo apt-get update -qq && sudo apt-get install -y -qq cmake libcurl4-openssl-dev
  [ -d ~/llama.cpp ] || git clone -q https://github.com/ggml-org/llama.cpp ~/llama.cpp
  cd ~/llama.cpp
  git fetch -q origin "pull/${PR}/head:pr${PR}"
  git checkout -q "pr${PR}"
  cmake -S . -B build -DCMAKE_BUILD_TYPE=Release -DLLAMA_CURL=ON
  cmake --build build --target llama-diffusion-cli -j "$(nproc)"
fi

# Free whatever Ollama is holding; BF16 needs ~51 GB of the 62 GB available.
command -v ollama >/dev/null && ollama stop --all 2>/dev/null || true

# llama-server can load this model but cannot decode it ("the current context
# does not logits computation"), so there is no Open WebUI path. CLI only.
exec ~/llama.cpp/build/bin/llama-diffusion-cli \
  -hf "${REPO}:${QUANT}" -cnv -t "$(nproc)" --diffusion-steps 64 -n 128
