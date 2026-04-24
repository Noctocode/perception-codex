# Claude Code with Custom LLM — PowerShell (Windows)

Route [Claude Code](https://docs.anthropic.com/en/docs/claude-code) through custom LLM backends on Windows using the `claudep` PowerShell function.

## Prerequisites

### Install Claude Code

**PowerShell:**

```powershell
irm https://claude.ai/install.ps1 | iex
```

**CMD:**

```batch
curl -fsSL https://claude.ai/install.cmd -o install.cmd && install.cmd && del install.cmd
```

Other install methods (WinGet, npm) are also available. See the [Claude Code setup docs](https://docs.anthropic.com/en/docs/claude-code/setup) for details.

Verify installation:

```powershell
claude --version
```

### Custom LLM backend

You need a LiteLLM-compatible endpoint (or any OpenAI-compatible API) that translates chat completions into the Anthropic Messages format. `claudep` sets `LITELLM_USE_CHAT_COMPLETIONS_URL_FOR_ANTHROPIC_MESSAGES=true` to enable this routing.

## Setup

1. Find your profile path:

```powershell
echo $PROFILE
# Typically: C:\Users\<you>\Documents\WindowsPowerShell\Microsoft.PowerShell_profile.ps1
```

2. Append the script to your profile:

```powershell
# If profile doesn't exist yet
New-Item -Path $PROFILE -Type File -Force

# Append
Get-Content .\Microsoft.PowerShell_profile.ps1 | Add-Content $PROFILE
```

Or add a dot-source line instead:

```powershell
Add-Content $PROFILE ". S:\path\to\perception-codex\Microsoft.PowerShell_profile.ps1"
```

3. Reload your profile:

```powershell
. $PROFILE
```

## Configure LLM endpoints

Edit the env var declarations at the top of your profile. Fill in the URL, API key, and model name for each backend you want to use:

```powershell
$env:LLM_1_URL = "https://my-custom-llm-1.example.com"
$env:LLM_1_API_KEY = "sk-..."
$env:LLM_1_MODEL = "glm-5-1-fp8"

$env:LLM_2_URL = "https://my-custom-llm-2.example.com"
$env:LLM_2_API_KEY = "sk-..."
$env:LLM_2_MODEL = "gemma-4-31b"

$env:LLM_3_URL = "https://my-custom-llm-3.example.com"
$env:LLM_3_API_KEY = "sk-..."
$env:LLM_3_MODEL = "my-custom-model"
```

After editing, reload your profile.

## Usage

```powershell
claudep [model] [claude-args...]
```

| Argument          | Behavior                       |
| ----------------- | ------------------------------ |
| `llm1`            | Route through LLM 1 endpoint   |
| `llm2`            | Route through LLM 2 endpoint   |
| `llm3`            | Route through LLM 3 endpoint   |
| _(none or other)_ | Default Anthropic subscription |

### Default subscription (no custom backend)

```powershell
claudep
```

Uses your existing Anthropic subscription. No env var overrides applied — passes straight through to `claude`.

### Custom LLM

```powershell
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

Add a new `LLM_X_URL` / `LLM_X_API_KEY` / `LLM_X_MODEL` declaration at the top of the profile, then add a matching case block inside the `switch` statement:

```powershell
"llm4" {
    if (-not $env:LLM_4_URL -or -not $env:LLM_4_API_KEY -or -not $env:LLM_4_MODEL) {
        Write-Host "Error: LLM_4_URL, LLM_4_API_KEY, and LLM_4_MODEL must be set" -ForegroundColor Red
        return 1
    }
    $env:ANTHROPIC_BASE_URL = $env:LLM_4_URL
    $env:ANTHROPIC_API_KEY = $env:LLM_4_API_KEY
    $modelName = $env:LLM_4_MODEL
}
```

Keep the Zsh/Bash implementation in sync — see [Zsh/Bash docs](zsh.md).

## How it works

`claudep` is a thin wrapper around the `claude` CLI. It manipulates environment variables before launching Claude Code:

- **Session wipe** — deletes `~/.claude-code/sessions/*` so each invocation starts clean
- **Env var reset** — unsets all `ANTHROPIC_*` and `CLAUDE_CODE_*` vars to prevent config leaking between invocations
- **Model routing** — sets `ANTHROPIC_BASE_URL` to your custom endpoint and overrides all model tier vars to your chosen model name
- **LiteLLM bridge** — `LITELLM_USE_CHAT_COMPLETIONS_URL_FOR_ANTHROPIC_MESSAGES=true` tells Claude Code to route Anthropic Messages API calls through LiteLLM's chat completions translation layer
- **Billing bypass** — `CLAUDE_CODE_BILLING_PROVIDER=anthropic-console` skips the subscription check so API-key auth works
- **Noise suppression** — disables telemetry, update checks, and experimental betas that may not work with custom backends
