# ace-llm-query Usage Examples

## Overview

The `ace-llm-query` command provides a unified interface for querying any LLM provider. It maintains full compatibility with the existing `llm-query` command while integrating with the ace-* gem ecosystem.

## Basic Usage

### Simple Query with Provider

```bash
# Query Google Gemini with explicit model
$ ace-llm-query google:gemini-2.5-flash "What is Ruby programming?"

Ruby is a dynamic, interpreted, object-oriented programming language known for its
simplicity and productivity. Created by Yukihiro "Matz" Matsumoto in 1995, Ruby
emphasizes programmer happiness with its elegant syntax that reads like natural language...

# Query with default model for provider
$ ace-llm-query google "Explain closures in JavaScript"

Closures in JavaScript are a fundamental concept where an inner function has access
to variables from its outer (enclosing) function's scope, even after the outer
function has returned...
```

### Using Aliases

```bash
# Use predefined aliases for quick access
$ ace-llm-query gflash "Write a haiku about coding"

Lines of logic flow,
Bugs hide in the semicolon,
Coffee fuels debug.

# Other common aliases
$ ace-llm-query opus "Analyze this code pattern"     # anthropic:claude-3-opus-20240229
$ ace-llm-query sonnet "Review this approach"        # anthropic:claude-3-sonnet-20240229
$ ace-llm-query o4mini "Quick calculation"          # openai:gpt-4o-mini
```

### File Input

```bash
# Use file as prompt input
$ ace-llm-query gflash prompt.txt

# With system prompt from file
$ ace-llm-query openai:gpt-4o code_review.md --system guidelines.md

# Combine file prompt with system instruction
$ ace-llm-query anthropic:claude-sonnet-4-20250514 implementation.rb \
    --system "You are a Ruby expert. Review this code for best practices."
```

## Output Formatting

### Save to File

```bash
# Output to markdown file (format inferred from extension)
$ ace-llm-query gflash "Explain Docker containers" --output containers.md

Response saved to: containers.md

# Output to JSON file
$ ace-llm-query opus "List 5 Python best practices" --output practices.json --format json

{
  "response": {
    "practices": [
      "Use virtual environments for dependency management",
      "Follow PEP 8 style guidelines",
      "Write comprehensive unit tests",
      "Use type hints for better code clarity",
      "Implement proper error handling with specific exceptions"
    ]
  },
  "metadata": {
    "provider": "anthropic",
    "model": "claude-3-opus-20240229",
    "tokens": { "input": 12, "output": 87 }
  }
}

# Force overwrite existing file
$ ace-llm-query gflash "Update this content" --output existing.md --force
```

### Format Options

```bash
# Plain text (default)
$ ace-llm-query gflash "Simple question" --format text

# Markdown formatting
$ ace-llm-query gflash "Create a README template" --format markdown

# JSON structured output
$ ace-llm-query gflash "Parse this data" --format json
```

## Advanced Options

### Temperature Control

```bash
# Creative writing (higher temperature)
$ ace-llm-query gflash "Write a creative story opening" --temperature 1.5

# Deterministic output (lower temperature)
$ ace-llm-query gflash "Calculate this formula" --temperature 0.2

# Zero temperature for most consistent results
$ ace-llm-query opus "Generate SQL query" --temperature 0
```

### Token Limits

```bash
# Limit output length
$ ace-llm-query gflash "Summarize this article" --max-tokens 200

# Verbose output with more tokens
$ ace-llm-query opus "Detailed explanation" --max-tokens 4000
```

### Timeouts

```bash
# Custom timeout for slow connections
$ ace-llm-query google:gemini-2.5-pro "Complex analysis" --timeout 120

# Quick timeout for simple queries
$ ace-llm-query gflash "Yes or no question" --timeout 10
```

### Debug Mode

```bash
# Enable debug output for troubleshooting
$ ace-llm-query gflash "Test query" --debug

[DEBUG] Provider: google
[DEBUG] Model: gemini-2.5-flash
[DEBUG] API Endpoint: https://generativelanguage.googleapis.com/v1beta/
[DEBUG] Request tokens: 4
[DEBUG] Response tokens: 42
[DEBUG] Latency: 823ms
```

## Provider-Specific Features

### Local LM Studio

```bash
# Query local LM Studio instance
$ ace-llm-query lmstudio "Local inference test"

# With custom endpoint
$ ace-llm-query lmstudio "Query" --endpoint http://localhost:1234/v1
```

### OpenAI Compatible APIs

```bash
# Mistral AI
$ ace-llm-query mistral:mistral-medium "French translation"

# Together AI
$ ace-llm-query together:mixtral-8x7b "Parallel processing explanation"
```

## Configuration

### Show Available Aliases

```bash
# Show aliases for a specific provider
$ ace-llm-query google

Available aliases for Google:
  gflash  → google:gemini-2.5-flash
  gpro    → google:gemini-2.5-pro
  gfast   → google:gemini-2.5-flash-lite

# Show all configured aliases
$ ace-llm-query --list-aliases

Global aliases:
  gflash  → google:gemini-2.5-flash
  opus    → anthropic:claude-3-opus-20240229
  sonnet  → anthropic:claude-3-sonnet-20240229
  o4mini  → openai:gpt-4o-mini
  ...
```

### Cost Tracking

```bash
# Query with cost display
$ ace-llm-query opus "Complex task" --show-cost

[Response content...]

Cost: $0.0234 (Input: 15 tokens @ $15/M, Output: 487 tokens @ $75/M)

# Generate usage report
$ ace-llm-query --usage-report

Usage Report (Last 30 days):
  Google Gemini:  $2.34  (45,230 tokens)
  OpenAI GPT-4:   $8.92  (12,450 tokens)
  Anthropic:      $4.56  (23,100 tokens)
  Total:          $15.82
```

## Error Handling

### Missing Credentials

```bash
$ ace-llm-query gflash "Test"

Error: Google API credentials not found.
Please set one of the following environment variables:
  - GEMINI_API_KEY
  - GOOGLE_API_KEY

Or configure in ~/.ace/llm/credentials.yml
```

### Invalid Model

```bash
$ ace-llm-query google:invalid-model "Test"

Error: Model 'invalid-model' not found for provider 'google'.
Available models:
  - gemini-2.5-flash
  - gemini-2.5-pro
  - gemini-2.5-flash-lite
```

### Network Issues

```bash
$ ace-llm-query gflash "Query" --timeout 5

Error: Request timed out after 5 seconds.
Try increasing timeout with --timeout option or check your connection.
```

## Migration from llm-query

The new `ace-llm-query` command maintains full compatibility:

```bash
# Old command
$ llm-query google:gemini-2.5-flash "Question"

# New command (identical behavior)
$ ace-llm-query google:gemini-2.5-flash "Question"

# Configuration compatibility
# Old: .coding-agent/llm-aliases.yml
# New: .ace/llm/aliases.yml (with fallback to old location)
```

## Common Workflows

### Code Review

```bash
# Review code with specific guidelines
$ ace-llm-query opus implementation.rb \
    --system "Review for SOLID principles and Ruby idioms" \
    --output review.md \
    --format markdown
```

### Documentation Generation

```bash
# Generate API documentation
$ ace-llm-query gflash "Document this API endpoint" \
    --system "Follow OpenAPI 3.0 specification" \
    --max-tokens 2000 \
    --output api-docs.yml
```

### Quick Translations

```bash
# Translate content
$ ace-llm-query gflash "Translate to Spanish: Hello world" --temperature 0.3

Hola mundo
```

### Data Analysis

```bash
# Analyze CSV data
$ cat data.csv | ace-llm-query opus \
    --system "Analyze this CSV data and provide insights" \
    --format json \
    --output analysis.json
```

## Exit Codes

- `0` - Success
- `1` - General error (invalid arguments, API errors, etc.)
- `2` - Configuration error (missing credentials, invalid config)
- `3` - Network error (timeout, connection failed)
- `130` - User interrupted (Ctrl+C)

## Environment Variables

```bash
# API Keys
export GEMINI_API_KEY="your-key"
export OPENAI_API_KEY="your-key"
export ANTHROPIC_API_KEY="your-key"

# Configuration paths (optional)
export ACE_CONFIG_HOME="$HOME/.ace"
export XDG_CONFIG_HOME="$HOME/.config"
export XDG_CACHE_HOME="$HOME/.cache"

# Debug settings
export ACE_LLM_DEBUG=1
export ACE_LLM_SHOW_COST=1
```

## Tips and Best Practices

1. **Use aliases** for frequently used models to save typing
2. **Set temperature** appropriately: low for factual queries, high for creative tasks
3. **Use system prompts** to establish context and get better responses
4. **Save important responses** with `--output` for future reference
5. **Enable debug mode** when troubleshooting API issues
6. **Set reasonable timeouts** based on query complexity
7. **Use JSON format** when you need structured data for further processing
8. **Configure aliases** in `.ace/llm/aliases.yml` for team consistency

## See Also

- Configuration guide: `ace-llm/docs/configuration.md`
- Provider setup: `ace-llm/docs/providers.md`
- API reference: `ace-llm/docs/api.md`