# ace-llm-models Enhanced CLI Usage

## Overview

Enhanced CLI commands for querying LLM model information from models.dev:
- `info` - Complete model details
- `cost` - Pricing calculations (with JSON output)
- `search` - Flexible model discovery with filters

## Commands

### info - Model Information

Display complete information about a specific model.

```bash
# Human-readable output
ace-llm-models info anthropic:claude-sonnet-4-20250514

# JSON output (for scripting/piping)
ace-llm-models info anthropic:claude-sonnet-4-20250514 --json
```

**Output includes:**
- Model name and ID
- Provider
- Status (active, deprecated, preview, etc.)
- Capabilities (reasoning, tool_call, attachment, structured_output, temperature)
- Modalities (input/output types)
- Context and output limits
- Pricing (input, output, cache_read, cache_write, reasoning)
- Metadata (knowledge date, release date, last updated, open weights)

### cost - Pricing Calculator

Calculate costs for token usage (now with JSON output).

```bash
# Default calculation (1000 input, 500 output tokens)
ace-llm-models cost openai:gpt-4o

# Custom token counts
ace-llm-models cost openai:gpt-4o -i 5000 -o 2000

# With reasoning tokens
ace-llm-models cost anthropic:claude-sonnet-4-20250514 -i 1000 -o 500 -r 2000

# JSON output
ace-llm-models cost openai:gpt-4o --json
```

### search - Model Discovery

Search and filter models with flexible criteria.

```bash
# Basic search by name/ID
ace-llm-models search "claude"

# List all models (no query)
ace-llm-models search --limit 50

# Filter by provider
ace-llm-models search --filter provider:anthropic
ace-llm-models search -p openai  # shorthand

# Filter by capabilities
ace-llm-models search --filter reasoning:true
ace-llm-models search --filter tool_call:true --filter attachment:true

# Filter by modality
ace-llm-models search --filter modality:image
ace-llm-models search --filter modality:audio

# Filter by context size
ace-llm-models search --filter min_context:100000

# Filter by cost
ace-llm-models search --filter max_input_cost:1

# Filter by open weights
ace-llm-models search --filter open_weights:true

# Combine multiple filters (AND logic)
ace-llm-models search --filter provider:openai --filter reasoning:true --filter min_context:100000

# JSON output
ace-llm-models search --filter provider:anthropic --json
```

## Filter Reference

| Filter | Values | Description |
|--------|--------|-------------|
| `provider` | provider ID | Filter by provider (openai, anthropic, etc.) |
| `reasoning` | true/false | Has reasoning/thinking capability |
| `tool_call` | true/false | Supports function/tool calling |
| `attachment` | true/false | Supports file attachments |
| `open_weights` | true/false | Open weights model |
| `modality` | text/image/audio/video | Supports input modality |
| `min_context` | number | Minimum context window size |
| `max_input_cost` | number | Maximum input cost per million tokens |

## JSON Output Examples

### info --json

```json
{
  "id": "claude-sonnet-4-20250514",
  "full_id": "anthropic:claude-sonnet-4-20250514",
  "name": "Claude Sonnet 4",
  "provider_id": "anthropic",
  "status": null,
  "capabilities": {
    "reasoning": true,
    "tool_call": true,
    "attachment": true,
    "structured_output": true,
    "temperature": true
  },
  "modalities": {
    "input": ["text", "image"],
    "output": ["text"]
  },
  "limits": {
    "context": 200000,
    "output": 64000
  },
  "pricing": {
    "input": 3.0,
    "output": 15.0,
    "cache_read": 0.3
  },
  "knowledge_date": "2025-04",
  "release_date": "2025-05-14",
  "last_updated": "2025-05-14",
  "open_weights": false
}
```

### search --json

Returns a paginated result object:

```json
{
  "models": [
    {
      "id": "claude-sonnet-4-20250514",
      "full_id": "anthropic:claude-sonnet-4-20250514",
      "name": "Claude Sonnet 4",
      ...
    },
    {
      "id": "claude-opus-4-20250514",
      "full_id": "anthropic:claude-opus-4-20250514",
      "name": "Claude Opus 4",
      ...
    }
  ],
  "showing": 2,
  "total": 15
}
```

- `models`: Array of model objects (limited by `--limit`)
- `showing`: Number of models in this response
- `total`: Total matching models (before limit)

## Common Use Cases

### Find cheapest reasoning models
```bash
ace-llm-models search --filter reasoning:true --filter max_input_cost:1
```

### Find models with large context windows
```bash
ace-llm-models search --filter min_context:100000 --limit 50
```

### Find open-source alternatives
```bash
ace-llm-models search --filter open_weights:true --filter reasoning:true
```

### Get model info for scripting
```bash
# Get context limit
ace-llm-models info openai:gpt-4o --json | jq '.limits.context'

# Get input cost
ace-llm-models info anthropic:claude-sonnet-4 --json | jq '.pricing.input'
```

### List all models from a provider
```bash
ace-llm-models search --filter provider:google --limit 100
```
