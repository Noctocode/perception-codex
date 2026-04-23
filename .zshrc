export LLM_1_URL=""
export LLM_1_API_KEY=""
export LLM_1_MODEL=""

export LLM_2_URL=""
export LLM_2_API_KEY=""
export LLM_2_MODEL=""

export LLM_3_URL=""
export LLM_3_API_KEY=""
export LLM_3_MODEL=""

claudep() {
    # First argument selects model, remaining args passed to claude
    local Model=$1
    shift

    # Env vars that must be cleared before each invocation to avoid stale config
    varsList=(
        "ANTHROPIC_BASE_URL"                                   # API endpoint URL
        "ANTHROPIC_API_KEY"                                    # API authentication key
        "ANTHROPIC_MODEL"                                      # Default model override
        "ANTHROPIC_DEFAULT_OPUS_MODEL"                         # Opus-tier override
        "ANTHROPIC_DEFAULT_SONNET_MODEL"                       # Sonnet-tier override
        "ANTHROPIC_DEFAULT_HAIKU_MODEL"                        # Haiku-tier override
        "ANTHROPIC_CUSTOM_MODEL_OPTION"                        # Model ID in picker
        "ANTHROPIC_CUSTOM_MODEL_OPTION_NAME"                   # Display name in picker
        "LITELLM_USE_CHAT_COMPLETIONS_URL_FOR_ANTHROPIC_MESSAGES"  # LiteLLM routing flag
        "CLAUDE_CODE_MAX_OUTPUT_TOKENS"                        # Max tokens in response
        "CLAUDE_CODE_BLOCKING_LIMIT_OVERRIDE"                  # Override for blocking call limit
        "CLAUDE_CODE_SESSION_ID"                               # Active session identifier
        "CLAUDE_CODE_BILLING_PROVIDER"                         # Billing backend selection
        "CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC"             # Kill telemetry/updates
        "CLAUDE_CODE_DISABLE_EXPERIMENTAL_BETAS"               # Kill experimental features
    )

    # Wipe session state — forces fresh start, no leftover context from prior runs
    if [ -d "$HOME/.claude-code/sessions" ]; then
        find "$HOME/.claude-code/sessions" -mindepth 1 -delete 2>/dev/null
    fi
    echo "Cleared Claude Code sessions."

    # Unset all vars from list — guarantee clean state regardless of shell history
    for var in "${varsList[@]}"; do
        unset "$var"
    done
    echo "Cleared env vars."

    local modelName=""

    case "$Model" in
        "llm1")
            # Validate required env vars for this backend
            if [[ -z "$LLM_1_URL" || -z "$LLM_1_API_KEY" || -z "$LLM_1_MODEL" ]]; then
                echo "Error: LLM_1_URL, LLM_1_API_KEY, and LLM_1_MODEL must be set"
                return 1
            fi
            export ANTHROPIC_BASE_URL="$LLM_1_URL"             # Point to LLM 1 endpoint
            export ANTHROPIC_API_KEY="$LLM_1_API_KEY"          # Authenticate against LLM 1
            modelName="$LLM_1_MODEL"

            # Model-specific overrides — uncomment and adjust per model needs
            # export CUSTOM_ENV_VAR_1=0
            # export CUSTOM_ENV_VAR_2=0
            ;;
        "llm2")
            if [[ -z "$LLM_2_URL" || -z "$LLM_2_API_KEY" || -z "$LLM_2_MODEL" ]]; then
                echo "Error: LLM_2_URL, LLM_2_API_KEY, and LLM_2_MODEL must be set"
                return 1
            fi
            export ANTHROPIC_BASE_URL="$LLM_2_URL"             # Point to LLM 2 endpoint
            export ANTHROPIC_API_KEY="$LLM_2_API_KEY"          # Authenticate against LLM 2
            modelName="$LLM_2_MODEL"

            # Model-specific overrides — uncomment and adjust per model needs
            # export CUSTOM_ENV_VAR_1=0
            # export CUSTOM_ENV_VAR_2=0
            ;;
        "llm3")
            if [[ -z "$LLM_3_URL" || -z "$LLM_3_API_KEY" || -z "$LLM_3_MODEL" ]]; then
                echo "Error: LLM_3_URL, LLM_3_API_KEY, and LLM_3_MODEL must be set"
                return 1
            fi
            export ANTHROPIC_BASE_URL="$LLM_3_URL"             # Point to LLM 3 endpoint
            export ANTHROPIC_API_KEY="$LLM_3_API_KEY"          # Authenticate against LLM 3
            modelName="$LLM_3_MODEL"

            # Model-specific overrides — uncomment and adjust per model needs
            # export CUSTOM_ENV_VAR_1=0
            # export CUSTOM_ENV_VAR_2=0
            ;;
        *)
            # No model matched — fall through to default Anthropic subscription
            echo "Switched to: Default subscription"
            claude "$@"
            return
            ;;
    esac

    # Register custom model in Claude Code's model picker
    export ANTHROPIC_CUSTOM_MODEL_OPTION="$modelName"       # Model ID shown in picker
    export ANTHROPIC_CUSTOM_MODEL_OPTION_NAME="$modelName"  # Display name in picker

    # Force all Claude Code model tiers to use the custom model
    export ANTHROPIC_MODEL="$modelName"                     # Default model override
    export ANTHROPIC_DEFAULT_OPUS_MODEL="$modelName"        # Opus-tier override
    export ANTHROPIC_DEFAULT_SONNET_MODEL="$modelName"      # Sonnet-tier override
    export ANTHROPIC_DEFAULT_HAIKU_MODEL="$modelName"       # Haiku-tier override

    # Route Anthropic Messages API calls through LiteLLM's chat completions translation
    export LITELLM_USE_CHAT_COMPLETIONS_URL_FOR_ANTHROPIC_MESSAGES="true"

    # Disable telemetry, update checks, and other non-essential network calls
    export CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC="1"
    # Disable experimental beta features that may not work with custom backends
    export CLAUDE_CODE_DISABLE_EXPERIMENTAL_BETAS="1"
    # Bypass subscription billing check — use Anthropic console/API key billing instead
    export CLAUDE_CODE_BILLING_PROVIDER="anthropic-console"

    echo "Switched to: Custom model ($modelName)"

    claude "$@"
}
