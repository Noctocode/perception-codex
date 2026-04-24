# Claude Code with Custom LLM — VS Code Extension

Configure the [Claude Code VS Code extension](https://docs.anthropic.com/en/docs/claude-code/ide-integrations) to route through a custom LLM backend via `claudeCode.environmentVariables` in `.vscode/settings.json`.

Works the same way as the CLI `claudep` wrapper — setting env vars that route Claude Code through your endpoint — but applied at the IDE level.

## Prerequisites

Install the Claude Code extension from the [VS Code Marketplace](https://marketplace.visualstudio.com/items?itemName=anthropic.claude-code).

## Fill in your endpoint

Edit `.vscode/settings.json` and set the empty values:

```jsonc
{
  "claudeCode.environmentVariables": [
    { "name": "ANTHROPIC_BASE_URL", "value": "https://my-llm.example.com" },
    { "name": "ANTHROPIC_API_KEY", "value": "sk-..." },
    { "name": "ANTHROPIC_MODEL", "value": "glm-5-1-fp8" },
    // ...
  ]
}
```

## Switch between configs

### Method 1 — Prefix trick (rename the key)

The extension only reads the key `claudeCode.environmentVariables`. Rename it to disable:

```jsonc
// Disabled — extension ignores this
"disabled_claudeCode.environmentVariables": [ ... ]

// Re-enable by renaming back
"claudeCode.environmentVariables": [ ... ]
```

Keep multiple blocks with different prefixes in one file, rename the one you want active.

### Method 2 — Multiple settings files

Create variant files in `.vscode/`:

```
settings.llm1.json      ← LLM 1 endpoint config
settings.llm2.json      ← LLM 2 endpoint config
settings.default.json   ← no overrides (plain Anthropic)
```

Switch by copying the desired variant over `settings.json`:

```powershell
Copy-Item .vscode/settings.llm1.json .vscode/settings.json
```

```bash
cp .vscode/settings.llm1.json .vscode/settings.json
```

### Method 3 — Remove the block

Delete the entire `claudeCode.environmentVariables` array to fall back to default Anthropic auth.

## Env vars explained

| Variable | Purpose |
|----------|---------|
| `ANTHROPIC_BASE_URL` | Your LiteLLM / OpenAI-compatible endpoint URL |
| `ANTHROPIC_API_KEY` | API key for the custom endpoint |
| `ANTHROPIC_MODEL` | Override the default model name to your custom model ID |
| `CLAUDE_CODE_BILLING_PROVIDER` | Set to `anthropic-console` to bypass subscription check |
| `LITELLM_USE_CHAT_COMPLETIONS_URL_FOR_ANTHROPIC_MESSAGES` | Set to `1` to route Anthropic Messages through LiteLLM chat completions translation |
| `CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC` | Set to `1` to disable telemetry/update checks |
| `CLAUDE_CODE_DISABLE_EXPERIMENTAL_BETAS` | Set to `1` to disable betas incompatible with custom backends |

## Auth conflict warning

Same as the CLI wrapper — you may see the "Auth conflict" warning. It's harmless. `CLAUDE_CODE_BILLING_PROVIDER=anthropic-console` ensures your API key takes precedence.

## Also see

- [Zsh/Bash CLI setup](zsh.md)
- [PowerShell CLI setup](powershell.md)
