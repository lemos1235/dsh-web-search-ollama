# Draft — DeepSeek Harness Discussion / PR

**Title:** Ollama web search without DEEPSEEK_API_KEY (`dsh-web-search-ollama`)

## Problem

Running DSH against Ollama (custom OpenAI-compatible provider, e.g. `deepseek-v4-flash:cloud`) works for chat, but `web_search` still uses `@deepseek-ai/dsh-web-search-deepseek`:

```
Error: DeepSeek search has no API key for "DEEPSEEK_API_KEY"; store it through the credentials service
```

`ollama launch dsh` is documented as pre-installing Ollama web search, but Ollama 0.32.4 does not expose a `dsh` launch target (`claude`, `hermes`, `opencode`, `pi`, … only).

## What we did

A profile bundle that:

- registers `ctx.web` search + fetch providers `id: ollama`
- sets `searchProvider` / `fetchProvider` to `ollama`
- disables `web-search-deepseek`
- calls the signed-in local host:
  - `POST http://127.0.0.1:11434/api/experimental/web_search`
  - fallback `POST /api/web_search`

Verified: headless `web_search` for “Ollama official website” returned `https://ollama.com/`.

Repo: https://github.com/mrmoradzekri-hub/dsh-web-search-ollama

Install:

```sh
dsh plugin --profile web add -w github:mrmoradzekri-hub/dsh-web-search-ollama
```

## Ask

1. Community plugin is enough for now, or do you want a first-party `@deepseek-ai/dsh-web-search-ollama`?
2. If first-party: should it live next to `dsh-web-search-deepseek` / `dsh-web-search-exa`, selected via `DSH_WEB_SEARCH_PROVIDER=ollama`?
3. Please treat `/api/experimental/web_search` as a compatibility path until Ollama ships `ollama launch dsh` everywhere.
