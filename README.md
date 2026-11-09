# Ollama web search / Ollama 网页搜索

Ollama-backed `web_search` and `web_fetch` for [DeepSeek Harness](https://github.com/deepseek-ai/deepseek-harness): the agent searches through a local signed-in Ollama host — no `DEEPSEEK_API_KEY`.

## Config

```yaml
- id: web-search-ollama
  name: dsh-web-search-ollama
  config:
    host: http://127.0.0.1:11434
```
