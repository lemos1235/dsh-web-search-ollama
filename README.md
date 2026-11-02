# dsh-web-search-ollama

Ollama-backed `web_search` and `web_fetch` for [DeepSeek Harness](https://github.com/deepseek-ai/deepseek-harness).

Stock DSH routes `web_search` through DeepSeek (`DEEPSEEK_API_KEY`). If you run the agent on **Ollama Cloud / local Ollama**, that key is missing and every search fails:

```
Error: DeepSeek search has no API key for "DEEPSEEK_API_KEY"
```

This plugin registers an `ollama` provider on `ctx.web` and points the web seam at it. Search goes through your signed-in Ollama host — no DeepSeek API key.

## Install

```sh
dsh plugin --profile web add -w github:mrmoradzekri-hub/dsh-web-search-ollama
```

Local checkout:

```sh
dsh plugin --profile web add -w /path/to/dsh-web-search-ollama
```

Restart `dsh web`. Start a **new** session (old turns still carry the DeepSeek error).

## What it changes

| Row | Effect |
|---|---|
| `web.searchProvider` | `ollama` |
| `web.fetchProvider` | `ollama` |
| `web-search-deepseek` | disabled |
| `web-search-ollama` | mounted |

The agent preset still has `web_fetch: false`, so the model mainly gets **search**. Fetch is registered for when a preset enables it.

## How it talks to Ollama

Against `http://127.0.0.1:11434`, in this order:

1. `POST /api/experimental/web_search` (works on Ollama 0.32.x)
2. `POST /api/web_search` (stable path, when present)

Same pattern for fetch. No API key: the local daemon uses the signed-in Ollama account.

## Config

```yaml
- id: web-search-ollama
  name: dsh-web-search-ollama
  config:
    host: http://127.0.0.1:11434
```

## Why this is a plugin, not a DSH core patch

`ollama launch dsh` is supposed to inject Ollama search, but that integration is missing on some Ollama versions (0.32.4 has `hermes` / `opencode` / `pi`, not `dsh`). This bundle fills that gap without forking Harness.

## License

MIT
