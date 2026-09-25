#!/usr/bin/env bash
# Pull a bigger model. Usage: ./pull.sh llama3.3:70b
set -euo pipefail
df -h /  | tail -1
ollama pull "${1:?usage: ./pull.sh <model>}"
ollama list
