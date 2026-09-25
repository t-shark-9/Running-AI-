#!/usr/bin/env bash
# Runs once, when the codespace is created.
set -euo pipefail

curl -fsSL https://ollama.com/install.sh | sh

bash "$(dirname "$0")/start.sh"

# Default model: MoE, so only ~3.6B of 20B params are active per token -> usable
# speed on CPU. Bigger models: ./pull.sh (see README).
# ponytail: one pull here, the rest on demand; a 40GB pull would blow the
# postCreate timeout.
ollama pull gpt-oss:20b
