# ace-llm

LLM provider integration for AI-assisted development. Query any LLM provider through a unified CLI interface with cost tracking and output formatting. Features a configuration-based provider architecture that supports dynamic provider registration via YAML files.

## Installation

Add this gem to your Gemfile:

```ruby
gem 'ace-llm', path: '../ace-llm'  # For local development
```

Or install it directly:

```bash
cd ace-llm
bundle install
bundle exec rake install
```

## Usage

### Basic Query

```bash
# Query with explicit provider and model
ace-llm google:gemini-2.5-flash "What is Ruby programming?"

# Use default model for provider
ace-llm google "Explain closures"

# Use aliases for quick access
ace-llm gflash "Write a haiku about coding"

# List available providers and their status
ace-llm --list-providers
```

### Common Aliases

- `gflash` → google:gemini-2.5-flash
- `gpro` → google:gemini-2.5-pro
- `opus` → anthropic:claude-3-opus-20240229
- `sonnet` → anthropic:claude-3-5-sonnet-20241022
- `gpt4o` → openai:gpt-4o
- `o4mini` → openai:gpt-4o-mini
- `grok` → xai:grok-3
- `grok4` → xai:grok-4
- `grok4fast` → xai:grok-4-fast

### Advanced Options

```bash
# Save output to file
ace-llm gflash "Explain Docker" --output docker.md

# Control temperature
ace-llm gflash "Creative story" --temperature 1.5

# Limit output length
ace-llm gflash "Summary" --max-tokens 200

# Add system prompt (replaces defaults)
ace-llm gflash code.rb --system "You are a Ruby expert"

# Append to system prompt (keeps defaults, adds context)
ace-llm gflash code.rb --system-append "Focus on performance"

# Combine both for layered control
ace-llm gflash code.rb --system base-prompt.md --system-append context.md

# Output as JSON
ace-llm gflash "List 5 tips" --format json --output tips.json

# Override model with --model flag
ace-llm google "What is Ruby?" --model gemini-2.0-flash-lite
ace-llm gflash "Quick test" --model gemini-pro  # Override alias model

# Use --prompt flag for explicit prompt specification
ace-llm google --prompt "What is Ruby?"
ace-llm gflash --prompt prompt.txt --output response.md
ace-llm google --prompt 'Query with "quotes" and $vars'  # Avoid escaping issues
```

### CLI Provider Args Passthrough

For CLI-based providers (Claude Code, Codex, OpenCode, Gemini CLI), you can pass
extra CLI flags directly to the underlying tool:

```bash
# Single flag (auto-prefixed with --)
ace-llm claude:sonnet "Hello" --cli-args dangerously-skip-permissions

# Multiple flags
ace-llm claude:sonnet "Hello" --cli-args "dangerously-skip-permissions verbose"

# Flags with values (preferred: use --flag value or flag=value)
ace-llm claude:sonnet "Hello" --cli-args "--model=claude-sonnet-4-0 --max-tokens=200"
ace-llm claude:sonnet "Hello" --cli-args "--model claude-sonnet-4-0"
```

Notes:
- Tokens without a leading `-` are auto-prefixed with `--`.
- Value arguments following a flag (e.g., `--model claude-sonnet-4-0`) are preserved.
- For flags that accept multiple values, prefer `--flag=value` or repeat the flag: `--flag=value1 --flag=value2`.
- API-based providers ignore `--cli-args`.
- `QueryInterface.query` also accepts `cli_args:` for programmatic use.
- Pass-through principle: `--cli-args` is forwarded directly to provider CLIs. Use only flags you trust and understand.

### System Prompt Control

Control how system prompts are handled by different providers:

**Replace defaults entirely** (`--system`):
```bash
# Full control over system prompt - replaces provider defaults
ace-llm claude:haiku --system "Generate only the commit message" --prompt "$(git diff --staged)"
```

**Append to defaults** (`--system-append`):
```bash
# Keeps provider defaults and adds your context
ace-llm claude:sonnet --system-append "This project uses ATOM architecture" --prompt "Review this code"
```

**Layered prompts** (both flags):
```bash
# Base instructions + task-specific context
ace-llm claude:haiku --system standards.md --system-append task-context.md --prompt "Generate code"
```

**Provider behavior**:
- **Claude** (via Claude Code CLI): Maps to `--system-prompt` and `--append-system-prompt`
- **API providers** (Anthropic, OpenAI, Google): Concatenates both into single system message

## Configuration

### API Keys

Set environment variables for each provider:

```bash
export GEMINI_API_KEY="your-key"      # or GOOGLE_API_KEY
export OPENAI_API_KEY="your-key"
export ANTHROPIC_API_KEY="your-key"
export MISTRAL_API_KEY="your-key"
export TOGETHER_API_KEY="your-key"    # or TOGETHERAI_API_KEY
export XAI_API_KEY="your-key"         # x.ai / Grok
export GROQ_API_KEY="your-key"        # Groq ultra-fast inference
export OPENROUTER_API_KEY="your-key"  # OpenRouter unified API
export ZAI_API_KEY="your-key"         # Z.AI / GLM models
```

### Aliases Configuration

Create custom aliases in `.ace/llm/aliases.yml`:

```yaml
global:
  mymodel: "google:gemini-2.5-flash"
  quick: "openai:gpt-4o-mini"

providers:
  google:
    flash: "gemini-2.5-flash"
    pro: "gemini-2.5-pro"
```

### Execution Presets

Execution presets can be selected with `--preset <name>` or `provider:model@<name>`.

Preset resolution is provider-aware:
1. Load global preset `.ace/llm/presets/<name>.yml`
2. Overlay provider preset `.ace/llm/presets/<provider>/<name>.yml` (if present)

This keeps shared defaults in one place and allows provider-specific overrides for the same preset name.

Example:

```yaml
# .ace/llm/presets/review-deep.yml
timeout: 600
max_tokens: 16384
temperature: 0.1
cli_args:
  - "--verbose"
```

```yaml
# .ace/llm/presets/codex/review-deep.yml
cli_args:
  - "--full-auto"
  - "-c"
  - 'sandbox_mode="read-only"'
  - "-c"
  - 'model_reasoning_effort="high"'
```

```yaml
# .ace/llm/presets/claude/review-fast.yml
cli_args:
  - "--effort"
  - "medium"
```

```yaml
# .ace/llm/presets/claude/review-deep.yml
cli_args:
  - "--effort"
  - "high"
```

```yaml
# .ace/llm/presets/gemini/review-fast.yml
cli_args:
  - "--approval-mode"
  - "plan"
  - "--sandbox"
```

```yaml
# .ace/llm/presets/gemini/review-deep.yml
cli_args:
  - "--approval-mode"
  - "plan"
  - "--sandbox"
```

`cli_args` accepts either a string or an array of arguments in preset files.

Built-in defaults ship the same pattern in:
- `.ace-defaults/llm/presets/review-fast.yml`
- `.ace-defaults/llm/presets/review-deep.yml`
- `.ace-defaults/llm/presets/codex/review-fast.yml`
- `.ace-defaults/llm/presets/codex/review-deep.yml`
- `.ace-defaults/llm/presets/claude/review-fast.yml`
- `.ace-defaults/llm/presets/claude/review-deep.yml`
- `.ace-defaults/llm/presets/gemini/review-fast.yml`
- `.ace-defaults/llm/presets/gemini/review-deep.yml`

### Provider Configuration

Providers are now configured via YAML files in `.ace/llm/providers/`. You can add custom providers or override default configurations:

```yaml
# .ace/llm/providers/custom-provider.yml
name: custom-provider
class: CustomProviders::MyLLMClient
gem: custom-llm-provider  # External gem
models:
  - model-1
  - model-2
api_key:
  env: CUSTOM_API_KEY
  required: true
capabilities:
  - text_generation
  - streaming
default_options:
  temperature: 0.7
  max_tokens: 4096
```

#### Configuration Search Paths

Provider configurations are loaded from (in order):
1. Project `.ace/llm/providers/` directory
2. User config `~/.config/ace-llm/providers/`
3. Gem built-in `.ace-defaults/llm/providers/` directory

First configuration found wins if there are duplicates.

### Fallback Configuration

ace-llm supports automatic provider fallback with retry logic for improved reliability. When a provider fails due to transient errors (503, 429, timeouts), the system will automatically retry with exponential backoff and fall back to alternative providers.

#### Primary YAML Configuration

Configure fallback centrally in `.ace/llm/config.yml`:

```yaml
# .ace/llm/config.yml
llm:
  fallback:
    enabled: true
    retry_count: 3
    retry_delay: 1.0
    max_total_timeout: 30.0
    providers:
      - anthropic:claude-3-5-sonnet
      - openai:gpt-4o
      - google:gemini-2.5-flash
```

This shared `llm.fallback` policy is used by both `Ace::LLM::QueryInterface` callers (for example `ace-git-commit`) and `ace-llm query`.

#### Legacy Environment Overrides

Environment variables are still supported for compatibility and temporary overrides:

```bash
export ACE_LLM_FALLBACK_ENABLED=true
export ACE_LLM_FALLBACK_RETRY_COUNT=3
export ACE_LLM_FALLBACK_RETRY_DELAY=1.0
export ACE_LLM_FALLBACK_MAX_TOTAL_TIMEOUT=30.0
# Backward-compatible alias still accepted:
export ACE_LLM_FALLBACK_MAX_TIMEOUT=30.0
export ACE_LLM_FALLBACK_PROVIDERS="anthropic:claude-3-5-sonnet,openai:gpt-4o"
```

#### Provider Chain Examples

**Simple fallback chain** (same capability providers):
```yaml
providers:
  - anthropic:claude-3-5-sonnet
  - anthropic:claude-3-opus
  - openai:gpt-4o
```

**Cost-optimized chain** (try cheaper models first):
```yaml
providers:
  - google:gemini-2.5-flash   # Fast and cheap
  - anthropic:claude-3-haiku  # Fast fallback
  - openai:gpt-4o             # Premium fallback
```

**Multi-provider reliability** (different providers for resilience):
```yaml
providers:
  - google:gemini-2.5-flash
  - anthropic:claude-3-5-sonnet
  - openai:gpt-4o-mini
```

**Local + Cloud hybrid**:
```yaml
providers:
  - lmstudio:local-model      # Try local first
  - google:gemini-2.5-flash   # Cloud fallback
  - anthropic:claude-3-5-sonnet
```

#### How Fallback Works

1. **Primary provider fails** → Retry with exponential backoff (default: 3 attempts)
2. **Retries exhausted** → Move to next provider in fallback chain
3. **Repeat** for each provider in the chain
4. **All providers fail** → Return error with helpful diagnostics

**Error Classification**:
- **Retry with backoff**: overload/unavailable/rate-limit style failures (including HTTP 429/500/502/503/504)
- **Skip to next immediately**: auth failures, quota/credit/window-limit exhaustion, and timeouts
- **Terminal**: Invalid requests, unsupported operations

**User Feedback**:
```bash
$ ace-llm google "Generate commit message"
⚠ google unavailable (503), retrying... (attempt 2/3)
⚠ google unavailable after 3 retries
ℹ Trying fallback provider anthropic:claude-3-5-sonnet...
✓ Fallback to claude-3-5-sonnet successful
```

#### Performance Characteristics

- **Overhead**: <2s for fallback scenarios (including retries)
- **Exponential backoff**: 1s → 2s → 4s (with 10-30% jitter to prevent thundering herd)
- **Retry-After header**: Respects rate limit headers when provided
- **Total timeout**: Prevents infinite retry loops (default: 30s)
- **Circular dependency detection**: Prevents trying the same provider twice

#### Programmatic Usage

```ruby
require 'ace/llm'

# Configure fallback
config = Ace::LLM::Models::FallbackConfig.new(
  enabled: true,
  retry_count: 3,
  retry_delay: 1.0,
  providers: ['anthropic:claude-3-5-sonnet', 'openai:gpt-4o'],
  max_total_timeout: 30.0
)

# Execute with fallback support
orchestrator = Ace::LLM::Molecules::FallbackOrchestrator.new(
  config: config,
  status_callback: ->(msg) { puts msg }  # Optional status updates
)

result = orchestrator.execute(
  primary_provider: 'google:gemini-2.5-flash',
  registry: Ace::LLM::Molecules::ClientRegistry.instance
) do |client|
  client.complete("Your prompt here")
end
```

## Supported Providers

All providers are now configuration-based and support dynamic loading:

- **Google** (Gemini models) - `gemini-2.5-flash`, `gemini-2.5-pro`
- **OpenAI** (GPT models) - `gpt-4o`, `gpt-4o-mini`, `gpt-3.5-turbo`
- **Anthropic** (Claude models) - `claude-3-5-sonnet`, `claude-3-opus`
- **x.ai** (Grok models) - `grok-3`, `grok-4`, `grok-4-fast`
- **Groq** (Ultra-fast inference) - `openai/gpt-oss-120b`, `openai/gpt-oss-20b`, `moonshotai/kimi-k2-instruct-0905`, `mistral-saba-24b`
- **OpenRouter** (400+ models) - Access models via unified API
- **Mistral** - `mistral-large-latest`, `mistral-small-latest`
- **Together AI** - Various open-source models
- **LM Studio** (local models) - Custom local models

Use `ace-llm --list-providers` to see available providers and their configuration status.

## Development

```bash
# Run tests
bundle exec rake test

# Run linter
bundle exec rake standard

# Install gem locally
bundle exec rake install
```

## Architecture

The gem follows the ATOM architecture pattern:

- **Atoms**: Pure functions (env_reader, http_client, xdg_directory_resolver, provider_config_validator)
- **Molecules**: Composed operations (client_registry, provider_loader, llm_alias_resolver, provider_model_parser, format_handlers)
- **Organisms**: Provider clients (base_client, google_client, etc.)
- **Commands**: CLI implementation using OptionParser

### Configuration-Based Provider Architecture

The new architecture features:
- **ClientRegistry**: Manages provider configurations and instantiation
- **ProviderLoader**: Handles dynamic gem and class loading
- **ProviderConfigValidator**: Validates provider configuration schemas
- **YAML-based configuration**: Define providers without code changes
- **Dynamic discovery**: Auto-discover providers from multiple directories
- **Gem-based plugins**: Support for provider gems as separate packages

## License

MIT License - See LICENSE.txt for details
