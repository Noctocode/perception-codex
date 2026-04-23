$env:LLM_1_URL = ""
$env:LLM_1_API_KEY = ""
$env:LLM_1_MODEL = ""

$env:LLM_2_URL = ""
$env:LLM_2_API_KEY = ""
$env:LLM_2_MODEL = ""

$env:LLM_3_URL = ""
$env:LLM_3_API_KEY = ""
$env:LLM_3_MODEL = ""

function claudep {
    param (
        [Parameter(Position = 0)]
        [string]$Model
    )

    # Env vars that must be cleared before each invocation to avoid stale config
    $varsList = @(
        "ANTHROPIC_BASE_URL",                                   # API endpoint URL
        "ANTHROPIC_API_KEY",                                    # API authentication key
        "ANTHROPIC_MODEL",                                      # Default model override
        "ANTHROPIC_DEFAULT_OPUS_MODEL",                         # Opus-tier override
        "ANTHROPIC_DEFAULT_SONNET_MODEL",                       # Sonnet-tier override
        "ANTHROPIC_DEFAULT_HAIKU_MODEL",                        # Haiku-tier override
        "ANTHROPIC_CUSTOM_MODEL_OPTION",                        # Model ID in picker
        "ANTHROPIC_CUSTOM_MODEL_OPTION_NAME",                   # Display name in picker
        "LITELLM_USE_CHAT_COMPLETIONS_URL_FOR_ANTHROPIC_MESSAGES",  # LiteLLM routing flag
        "CLAUDE_CODE_MAX_OUTPUT_TOKENS",                        # Max tokens in response
        "CLAUDE_CODE_BLOCKING_LIMIT_OVERRIDE",                  # Override for blocking call limit
        "CLAUDE_CODE_SESSION_ID",                               # Active session identifier
        "CLAUDE_CODE_BILLING_PROVIDER",                         # Billing backend selection
        "CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC",             # Kill telemetry/updates
        "CLAUDE_CODE_DISABLE_EXPERIMENTAL_BETAS"                # Kill experimental features
    )

    # Wipe session state — forces fresh start, no leftover context from prior runs
    if (Test-Path "$env:USERPROFILE\.claude-code\sessions") {
        Get-ChildItem "$env:USERPROFILE\.claude-code\sessions" | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
    }
    Write-Host "Cleared Claude Code sessions." -ForegroundColor Cyan

    # Unset all vars from list — guarantee clean state regardless of shell history
    foreach ($var in $varsList) {
        Remove-Item "Env:$var" -ErrorAction SilentlyContinue
    }
    Write-Host "Cleared env vars." -ForegroundColor Cyan

    $modelName = ""

    switch ($Model) {
        "llm1" {
            # Validate required env vars for this backend
            if (-not $env:LLM_1_URL -or -not $env:LLM_1_API_KEY -or -not $env:LLM_1_MODEL) {
                Write-Host "Error: LLM_1_URL, LLM_1_API_KEY, and LLM_1_MODEL must be set" -ForegroundColor Red
                return 1
            }
            $env:ANTHROPIC_BASE_URL = $env:LLM_1_URL              # Point to LLM 1 endpoint
            $env:ANTHROPIC_API_KEY = $env:LLM_1_API_KEY           # Authenticate against LLM 1
            $modelName = $env:LLM_1_MODEL

            # Model-specific overrides — uncomment and adjust per model needs
            # $env:CUSTOM_ENV_VAR_1 = "0"
            # $env:CUSTOM_ENV_VAR_2 = "0"
        }
        "llm2" {
            if (-not $env:LLM_2_URL -or -not $env:LLM_2_API_KEY -or -not $env:LLM_2_MODEL) {
                Write-Host "Error: LLM_2_URL, LLM_2_API_KEY, and LLM_2_MODEL must be set" -ForegroundColor Red
                return 1
            }
            $env:ANTHROPIC_BASE_URL = $env:LLM_2_URL              # Point to LLM 2 endpoint
            $env:ANTHROPIC_API_KEY = $env:LLM_2_API_KEY           # Authenticate against LLM 2
            $modelName = $env:LLM_2_MODEL

            # Model-specific overrides — uncomment and adjust per model needs
            # $env:CUSTOM_ENV_VAR_1 = "0"
            # $env:CUSTOM_ENV_VAR_2 = "0"
        }
        "llm3" {
            if (-not $env:LLM_3_URL -or -not $env:LLM_3_API_KEY -or -not $env:LLM_3_MODEL) {
                Write-Host "Error: LLM_3_URL, LLM_3_API_KEY, and LLM_3_MODEL must be set" -ForegroundColor Red
                return 1
            }
            $env:ANTHROPIC_BASE_URL = $env:LLM_3_URL              # Point to LLM 3 endpoint
            $env:ANTHROPIC_API_KEY = $env:LLM_3_API_KEY           # Authenticate against LLM 3
            $modelName = $env:LLM_3_MODEL

            # Model-specific overrides — uncomment and adjust per model needs
            # $env:CUSTOM_ENV_VAR_1 = "0"
            # $env:CUSTOM_ENV_VAR_2 = "0"
        }
        default {
            # No model matched — fall through to default Anthropic subscription
            Write-Host "Switched to: Default subscription" -ForegroundColor Cyan
            & claude @args
            return
        }
    }

    # Register custom model in Claude Code's model picker
    $env:ANTHROPIC_CUSTOM_MODEL_OPTION = $modelName       # Model ID shown in picker
    $env:ANTHROPIC_CUSTOM_MODEL_OPTION_NAME = $modelName  # Display name in picker

    # Force all Claude Code model tiers to use the custom model
    $env:ANTHROPIC_MODEL = $modelName                     # Default model override
    $env:ANTHROPIC_DEFAULT_OPUS_MODEL = $modelName        # Opus-tier override
    $env:ANTHROPIC_DEFAULT_SONNET_MODEL = $modelName      # Sonnet-tier override
    $env:ANTHROPIC_DEFAULT_HAIKU_MODEL = $modelName       # Haiku-tier override

    # Route Anthropic Messages API calls through LiteLLM's chat completions translation
    $env:LITELLM_USE_CHAT_COMPLETIONS_URL_FOR_ANTHROPIC_MESSAGES = "true"

    # Use PowerShell tool instead of Bash tool on Windows
    $env:CLAUDE_CODE_USE_POWERSHELL_TOOL = "1"

    # Disable telemetry, update checks, and other non-essential network calls
    $env:CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC = "1"
    # Disable experimental beta features that may not work with custom backends
    $env:CLAUDE_CODE_DISABLE_EXPERIMENTAL_BETAS = "1"
    # Bypass subscription billing check — use Anthropic console/API key billing instead
    $env:CLAUDE_CODE_BILLING_PROVIDER = "anthropic-console"

    Write-Host "Switched to: Custom model ($modelName)" -ForegroundColor Cyan

    & claude @args
}
