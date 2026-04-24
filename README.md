# perception-codex

Shell function that routes [Claude Code](https://docs.anthropic.com/en/docs/claude-code) through custom LLM backends via environment variable overrides. Works with any LiteLLM-compatible or OpenAI-compatible API endpoint.

## Quick start

You need [Claude Code](https://docs.anthropic.com/en/docs/claude-code/setup) installed and a custom LLM endpoint (LiteLLM / OpenAI-compatible API).

## Docs

| Platform            | Setup guide                      |
| ------------------- | -------------------------------- |
| macOS / Linux / WSL | [Zsh / Bash](docs/zsh.md)        |
| Windows             | [PowerShell](docs/powershell.md) |
| VS Code extension   | [VS Code](docs/vscode.md)        |

## Usage

```bash
claudep [model] [claude-args...]
```

| Argument          | Behavior                       |
| ----------------- | ------------------------------ |
| `llm1`            | Route through LLM 1 endpoint   |
| `llm2`            | Route through LLM 2 endpoint   |
| `llm3`            | Route through LLM 3 endpoint   |
| _(none or other)_ | Default Anthropic subscription |

## How it works

`claudep` is a thin wrapper around the `claude` CLI. It manipulates environment variables before launching Claude Code:

- **Session wipe** — deletes `~/.claude-code/sessions/*` so each invocation starts clean
- **Env var reset** — unsets all `ANTHROPIC_*` and `CLAUDE_CODE_*` vars to prevent config leaking between invocations
- **Model routing** — sets `ANTHROPIC_BASE_URL` to your custom endpoint and overrides all model tier vars to your chosen model name
- **LiteLLM bridge** — `LITELLM_USE_CHAT_COMPLETIONS_URL_FOR_ANTHROPIC_MESSAGES=true` tells Claude Code to route Anthropic Messages API calls through LiteLLM's chat completions translation layer
- **Billing bypass** — `CLAUDE_CODE_BILLING_PROVIDER=anthropic-console` skips the subscription check so API-key auth works
- **Noise suppression** — disables telemetry, update checks, and experimental betas that may not work with custom backends
