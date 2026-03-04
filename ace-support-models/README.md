# ace-support-models

Model metadata, validation, and cost tracking for ACE via [models.dev](https://models.dev/).

## Installation

```bash
gem install ace-support-models
```

### Migration from ace-llm-models-dev

If you were using `ace-llm-models-dev`, note that:
- The cache directory has changed from `~/.ace-local/ace-llm-models-dev` to `~/.ace-local/ace-models`
- You will need to run `ace-models cache sync` after upgrading to fetch fresh data
- You can safely delete the old cache directory: `rm -rf ~/.ace-local/ace-llm-models-dev`
- All existing functionality remains identical

## Usage

The CLI uses git-style subcommands organized into three groups:

- `cache` - Manage local models.dev cache
- `providers` - Work with provider configurations
- `models` - Search, query, and price models

Top-level shortcuts are available for common operations.

### Cache Commands

```bash
# Sync from models.dev API
ace-models cache sync
ace-models cache sync --force  # Force refresh

# View cache status
ace-models cache status
# Cache Status:
#   Cached: Yes
#   Fresh: Yes
#   Last sync: 2024-12-04T00:30:00Z
#
# Statistics:
#   Providers: 69
#   Models: 847

# Show changes since last sync
ace-models cache diff
# New models:
#   + anthropic:claude-opus-4-5
# Updated models:
#   ~ openai:gpt-4o: cost.output: 10.00 → 7.50

# Clear cache
ace-models cache clear
```

### Provider Commands

```bash
# List all providers with model counts
ace-llm-providers list
# Providers (69):
#   openrouter: 127 models
#   openai: 36 models
#   ...

# Show provider details
ace-llm-providers show openai
# Provider: openai
# Models (36):
#   gpt-4o
#     GPT-4o
#   gpt-4o-mini
#     GPT-4o mini
#   ...

# Sync provider YAML configs with models.dev
ace-llm-providers sync
ace-llm-providers sync --apply  # Apply changes
```

### Model Commands

```bash
# Search models
ace-models models search gpt
# Showing 20 of 207 results:
#   openai:gpt-4o
#     GPT-4o
#   ...

# Search with filters
ace-models models search --provider openai --limit 10
ace-models models search --filter "tool_call:true"

# Model info (brief by default)
ace-models models info openai:gpt-4o
# GPT-4o (openai:gpt-4o)
#   Provider: openai
#   Status: active
#   Context: 128,000 tokens
#   Pricing: $2.50/M input, $10.00/M output
#   Capabilities: tools, structured
#
# Use --full for complete details

# Full model info
ace-models models info openai:gpt-4o --full

# Calculate costs
ace-models models cost openai:gpt-4o --input 10000 --output 2000
# Model: GPT-4o (openai:gpt-4o)
#
# Input:     10K tokens × $2.50/M = $0.025
# Output:    2K tokens × $10.00/M = $0.020
#
# Total: $0.045
```

### Top-Level Shortcuts

Common operations available at the top level:

```bash
ace-models search gpt      # → models search gpt
ace-models info gpt-4o     # → models info gpt-4o
ace-models sync            # → cache sync
```

### JSON Output

All commands support `--json` for machine-readable output:

```bash
ace-models cache status --json
ace-llm-providers list --json
ace-models models search gpt --json
ace-models models info openai:gpt-4o --json
```

#### Search JSON Structure

The `search` command returns a paginated result object:

```json
{
  "models": [
    {
      "provider_id": "openai",
      "model_id": "gpt-4o",
      "name": "GPT-4o",
      "description": "...",
      "pricing": { "input": 2.5, "output": 10.0 },
      "capabilities": { ... }
    }
  ],
  "showing": 20,
  "total": 207
}
```

- `models`: Array of model objects (limited by `--limit`)
- `showing`: Number of models in this response
- `total`: Total matching models (before limit)

## Ruby API

```ruby
require "ace/support/models"

# Sync
Ace::Support::Models.sync

# Validate
Ace::Support::Models.validate("openai:gpt-4o")  # Returns ModelInfo
Ace::Support::Models.valid?("openai:gpt-4o")    # Returns boolean

# Cost
result = Ace::Support::Models.cost(
  "openai:gpt-4o",
  input_tokens: 10_000,
  output_tokens: 2_000
)
puts result[:formatted][:total]  # "$0.045"

# Diff
diff = Ace::Support::Models.diff
puts diff.summary
```

## Data Source

This gem uses data from [models.dev](https://models.dev/), an open-source database of AI models maintained by the SST team.

- API: https://models.dev/api.json
- GitHub: https://github.com/sst/models.dev

## License

MIT
