#!/usr/bin/env bash
# Runs once, when the codespace is created.
set -euo pipefail

curl -fsSL https://ollama.com/install.sh | sh

bash "$(dirname "$0")/start.sh"

# ponytail: no pull here. The model we actually want is 56 GB, which would blow
# the postCreate timeout. Pull it by hand: ollama pull qwen3.8:27b-bf16
