# ace-llm-models-dev

Model validation and cost tracking via [models.dev](https://models.dev/).

## Installation

```bash
gem install ace-llm-models-dev
```

## Usage

### Sync Models

Download and cache model data:

```bash
ace-llm-models sync
# Synced 847 models from 69 providers

ace-llm-models sync --force  # Force refresh
```

### Validate Models

Check if a model exists:

```bash
ace-llm-models validate openai:gpt-4o
# ✓ openai:gpt-4o is valid
#   Name: GPT-4o
#   Provider: openai
#   Status: active

ace-llm-models validate xai:grok-99
# ✗ Model 'xai:grok-99' not found. Did you mean: grok-3, grok-4?
```

### Calculate Costs

Estimate query costs:

```bash
ace-llm-models cost openai:gpt-4o --input 10000 --output 2000
# Model: GPT-4o (openai:gpt-4o)
#
# Input:     10K tokens × $2.50/M = $0.025
# Output:    2K tokens × $10.00/M = $0.020
#
# Total: $0.045
```

### Show Changes

See what's changed since last sync:

```bash
ace-llm-models diff
# New models:
#   + anthropic:claude-4-opus
# Updated models:
#   ~ openai:gpt-4o: cost.output: 10.00 → 7.50
# Removed models:
#   - google:gemini-1.0-pro
```

### Search Models

Find models by name:

```bash
ace-llm-models search gpt
# Found 12 model(s):
#   openai:gpt-4o
#     GPT-4o
#   openai:gpt-4o-mini
#     GPT-4o Mini
#   ...
```

### View Statistics

```bash
ace-llm-models stats
# Cache Status:
#   Cached: Yes
#   Fresh: Yes
#   Last sync: 2024-12-04T00:30:00Z
#
# Statistics:
#   Providers: 69
#   Models: 847
```

## Ruby API

```ruby
require "ace/llm/models_dev"

# Sync
Ace::LLM::ModelsDev.sync

# Validate
Ace::LLM::ModelsDev.validate("openai:gpt-4o")  # Returns ModelInfo
Ace::LLM::ModelsDev.valid?("openai:gpt-4o")    # Returns boolean

# Cost
result = Ace::LLM::ModelsDev.cost(
  "openai:gpt-4o",
  input_tokens: 10_000,
  output_tokens: 2_000
)
puts result[:formatted][:total]  # "$0.045"

# Diff
diff = Ace::LLM::ModelsDev.diff
puts diff.summary
```

## Data Source

This gem uses data from [models.dev](https://models.dev/), an open-source database of AI models maintained by the SST team.

- API: https://models.dev/api.json
- GitHub: https://github.com/sst/models.dev

## License

MIT
