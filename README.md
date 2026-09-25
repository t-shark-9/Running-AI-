# Running-AI-
## Running a local LLM in a Codespace

Open this repo in a **16-core / 64 GB RAM / 128 GB** Codespace. The devcontainer
installs [Ollama](https://ollama.com) and [Open WebUI](https://openwebui.com)
and pulls `gpt-oss:20b` on first create (~10 min).

When it's up:

- **Chat UI** — port `8080` auto-opens (Ports tab → Open WebUI). Auth is off.
- **API** — port `11434`: `curl localhost:11434/api/generate -d '{"model":"gpt-oss:20b","prompt":"hi"}'`
- **Terminal** — `ollama run gpt-oss:20b`

### Which model

No GPU here, so it's all CPU. Mixture-of-experts models only activate a few
billion params per token, which is why a 20B MoE beats a 32B dense model on
speed by an order of magnitude.

| Model | Disk | Active params | Feel on 16 CPU cores |
|---|---|---|---|
| `gpt-oss:20b` (default) | 14 GB | 3.6B | ~15-20 tok/s — usable |
| `qwen3:30b-a3b` | 19 GB | 3B | ~15-20 tok/s — usable |
| `qwen3:32b` | 20 GB | 32B (dense) | ~2 tok/s — slow |
| `llama3.3:70b` | 43 GB | 70B (dense) | <1 tok/s — biggest that fits, painful |

`gpt-oss:120b` (~63 GB) and anything above it will not fit in 64 GB RAM.

```bash
./pull.sh qwen3:30b-a3b
```

### Notes

- Models live in `~/.ollama` and survive a codespace stop/start, not a rebuild.
- After a rebuild, `.devcontainer/setup.sh` re-pulls the default model only.
- Ollama logs: `/tmp/ollama.log`. WebUI logs: `docker logs open-webui`.
