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

## Biggest model that fits: Qwen3.5-122B-A10B

```bash
./run-model.sh
```

122B total params, 10B active, quantized to `UD-IQ3_S` — 46.6 GB of weights
plus ~2-3 GB of KV cache at `-c 8192`. Leaves ~14 GB headroom on the 64 GB
machine. First run builds llama.cpp (~2 min) and downloads 46.6 GB (~15 min).
Serves an OpenAI-compatible API on port `8081`.

Expect **~2-5 tok/s**. CPU inference at this size is bound by memory bandwidth,
not core count: ~5 GB of weights get read per token.

### Why not Qwen3.8-Flash-Next

Its smallest published quant is `UD-IQ1_S` at 72.5 GB, which exceeds 64 GB of
RAM. It would run only by paging off disk, at well under 1 tok/s, and IQ1 is
degraded enough that the 35B model below beats it on output quality.

### Swapping models

```bash
REPO=bartowski/zai-org_GLM-4.5-Air-GGUF QUANT=IQ3_XXS ./run-model.sh   # 50.3 GB
REPO=unsloth/Qwen3.6-35B-A3B-GGUF       QUANT=Q8_0    ./run-model.sh   # 36.9 GB, ~10 tok/s
```

Disk is 128 GB total and each model is cached in `~/.cache/llama.cpp` — clear
old ones before pulling a third.

Point Open WebUI at it: Settings -> Connections -> OpenAI -> `http://localhost:8081/v1`,
any API key.
