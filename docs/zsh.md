# Claude Code with Custom LLM — Zsh / Bash

Route [Claude Code](https://docs.anthropic.com/en/docs/claude-code) through custom LLM backends on macOS / Linux / WSL using the `claudep` shell function.

## Prerequisites

### Install Claude Code

```bash
curl -fsSL https://claude.ai/install.sh | bash
```

Other install methods (Homebrew, apt/dnf/apk, npm) are also available. See the [Claude Code setup docs](https://docs.anthropic.com/en/docs/claude-code/setup) for details.

Verify installation:

```bash
claude --version
```

### Custom LLM backend

You need a LiteLLM-compatible endpoint (or any OpenAI-compatible API) that translates chat completions into the Anthropic Messages format. `claudep` sets `LITELLM_USE_CHAT_COMPLETIONS_URL_FOR_ANTHROPIC_MESSAGES=true` to enable this routing.

## Setup

1. Copy the function and env var declarations into your shell profile:

```bash
# Zsh
cat .zshrc >> ~/.zshrc

# Bash
cat .zshrc >> ~/.bashrc
```

Or source it directly — add this line to `~/.zshrc` or `~/.bashrc`:

```bash
source /path/to/perception-codex/.zshrc
```

2. Reload your shell:

```bash
source ~/.zshrc   # or source ~/.bashrc
```

## Configure LLM endpoints

Edit the env var declarations at the top of your profile. Fill in the URL, API key, and model name for each backend you want to use:

```bash
export LLM_1_URL="https://my-custom-llm-1.example.com"
export LLM_1_API_KEY="sk-..."
export LLM_1_MODEL="glm-5-1-fp8"

export LLM_2_URL="https://my-custom-llm-2.example.com"
export LLM_2_API_KEY="sk-..."
export LLM_2_MODEL="gemma-4-31b"

export LLM_3_URL="https://my-custom-llm-3.example.com"
export LLM_3_API_KEY="sk-..."
export LLM_3_MODEL="my-custom-model"
```

After editing, reload your shell.

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

### Default subscription (no custom backend)

```bash
claudep
```

Uses your existing Anthropic subscription. No env var overrides applied — passes straight through to `claude`.

### Custom LLM

```bash
claudep llm1

# Pass additional Claude Code flags
claudep llm2 --dangerously-skip-permissions
claudep llm3 --model-sonnet glm-5-1-fp8
```

The function will:

1. Clear `~/.claude-code/sessions/*` — fresh start, no leftover context
2. Unset all prior Claude Code env vars — no stale config
3. Validate that `LLM_X_URL`, `LLM_X_API_KEY`, and `LLM_X_MODEL` are set (error + exit if missing)
4. Set `ANTHROPIC_BASE_URL` and `ANTHROPIC_API_KEY` for the chosen endpoint
5. Override all model tiers (`ANTHROPIC_MODEL`, `OPUS`, `SONNET`, `HAIKU`) to the chosen model name
6. Set LiteLLM routing, disable telemetry/experimental betas, set billing provider
7. Launch `claude` with remaining arguments

### Auth conflict warning

When using a custom LLM, Claude Code may show this warning:

> ⚠ Auth conflict: Both a token (claude.ai) and an API key (ANTHROPIC_API_KEY) are set. This may lead to unexpected behavior.
> · Trying to use claude.ai? Unset the ANTHROPIC_API_KEY environment variable, or claude /logout then say "No" to the API key approval before login.
> · Trying to use ANTHROPIC_API_KEY? claude /logout to sign out of claude.ai.

This is expected and harmless. The `ANTHROPIC_API_KEY` is required for your custom backend, and `claudep` sets `CLAUDE_CODE_BILLING_PROVIDER=anthropic-console` to ensure it takes precedence. Everything works correctly despite the warning.

## Adding a new model

Add a new `LLM_X_URL` / `LLM_X_API_KEY` / `LLM_X_MODEL` declaration at the top of the profile, then add a matching case block inside the `case` statement:

```bash
"llm4")
    if [[ -z "$LLM_4_URL" || -z "$LLM_4_API_KEY" || -z "$LLM_4_MODEL" ]]; then
        echo "Error: LLM_4_URL, LLM_4_API_KEY, and LLM_4_MODEL must be set"
        return 1
    fi
    export ANTHROPIC_BASE_URL="$LLM_4_URL"
    export ANTHROPIC_API_KEY="$LLM_4_API_KEY"
    modelName="$LLM_4_MODEL"
    ;;
```

Keep the PowerShell implementation in sync — see [PowerShell docs](powershell.md).

## How it works

`claudep` is a thin wrapper around the `claude` CLI. It manipulates environment variables before launching Claude Code:

- **Session wipe** — deletes `~/.claude-code/sessions/*` so each invocation starts clean
- **Env var reset** — unsets all `ANTHROPIC_*` and `CLAUDE_CODE_*` vars to prevent config leaking between invocations
- **Model routing** — sets `ANTHROPIC_BASE_URL` to your custom endpoint and overrides all model tier vars to your chosen model name
- **LiteLLM bridge** — `LITELLM_USE_CHAT_COMPLETIONS_URL_FOR_ANTHROPIC_MESSAGES=true` tells Claude Code to route Anthropic Messages API calls through LiteLLM's chat completions translation layer
- **Billing bypass** — `CLAUDE_CODE_BILLING_PROVIDER=anthropic-console` skips the subscription check so API-key auth works
- **Noise suppression** — disables telemetry, update checks, and experimental betas that may not work with custom backends
