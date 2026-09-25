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

## GLM-4.5-Air on llama.cpp

```bash
./run-glm.sh
```

First run builds llama.cpp (~2 min on 16 cores) and downloads 50.3 GB of
weights in two shards (~15 min). Both shards are weights — they are one model
split across two files, and all of it has to be resident. Server comes up on
port `8081`, OpenAI-compatible.

RAM: 50.3 GB weights + ~2-3 GB KV cache at `-c 8192`. That fits 64 GB only
with Ollama's model unloaded, which `run-glm.sh` does for you. Raise context
with `CTX=16384 ./run-glm.sh` and watch `free -g` — KV cache grows linearly.

Expect **~2-5 tok/s**. 12B params activate per token, so each token reads ~5 GB
from RAM, and CPU inference at this size is bound by memory bandwidth, not cores.

Point Open WebUI at it: Settings → Connections → OpenAI → `http://localhost:8081/v1`,
any API key.
