# OpenRouter LLM Provider - Usage Guide

## Overview

OpenRouter integration provides unified access to 400+ models from multiple providers (OpenAI, Anthropic, Google, Meta, etc.) through a single API. This implementation adds OpenRouter as a new provider in the ace-llm gem, making it accessible via `ace-llm-query` CLI and the Ruby API.

**Key Features:**
- Single API key for 400+ models across providers
- OpenAI-compatible API with optional attribution headers
- Model format: `provider/model` (e.g., `openai/gpt-4o`, `anthropic/claude-3.5-sonnet`)
- Optional HTTP-Referer and X-Title headers for app attribution
- Built-in aliases for common models

## Command Types

This feature provides both CLI and Ruby API access:

**CLI Commands** (bash terminal):
```bash
ace-llm-query openrouter:openai/gpt-4o "Your prompt"
ace-llm-query or-sonnet "Your prompt"  # Using alias
```

**Ruby API** (programmatic usage):
```ruby
client = Ace::LLM::Organisms::OpenRouterClient.new
response = client.generate("Your prompt")
```

## Command Structure

### Basic Invocation

**Format:**
```bash
ace-llm-query [provider:model] [prompt] [options]
```

**Provider-Model Syntax:**
- Full: `openrouter:provider/model` (e.g., `openrouter:openai/gpt-4o`)
- Alias: `or-gpt4`, `or-sonnet`, `or-gemini`, `or-llama`

**Options:**
- `--temperature 0.7` - Control randomness (0-1)
- `--max-tokens 4096` - Limit response length

## Usage Scenarios

### Scenario 1: Simple Query with GPT-4o via OpenRouter

**Goal:** Query OpenAI's GPT-4o model through OpenRouter

**Steps:**
1. Set API key: `export OPENROUTER_API_KEY=sk-or-v1-...`
2. Run query: `ace-llm-query openrouter:openai/gpt-4o "Explain quantum computing"`

**Expected Output:**
```
Quantum computing is a revolutionary approach...

[metadata]
Provider: openrouter
Model: openai/gpt-4o
```

### Scenario 2: Using Model Aliases

**Goal:** Use convenient aliases for common models

**Steps:**
```bash
# Anthropic Claude 3.5 Sonnet
ace-llm-query or-sonnet "Write a haiku about code"

# Google Gemini 2.0 Flash
ace-llm-query or-gemini "Summarize this article..."

# Meta Llama 3.1 70B
ace-llm-query or-llama "Translate to Spanish: Hello"
```

### Scenario 3: Error Handling - Missing API Key

**Goal:** Handle missing credentials gracefully

**Steps:**
```bash
unset OPENROUTER_API_KEY
ace-llm-query or-sonnet "test"
```

**Expected Output:**
```
Error: No API key found for openrouter
Please set OPENROUTER_API_KEY
```

## Tips and Best Practices

### API Key Management

Store in `.ace/.env`:
```bash
echo "OPENROUTER_API_KEY=sk-or-v1-..." >> .ace/.env
```

### Model Selection

- Fast/cheap: `or-gemini` (Google Gemini 2.0 Flash)
- Balanced: `or-sonnet` (Claude 3.5 Sonnet)
- Powerful: `or-gpt4` (GPT-4o)
- Open: `or-llama` (Llama 3.1 70B)

## References

- **OpenRouter Documentation**: https://openrouter.ai/docs
- **Model List**: https://openrouter.ai/models
- **API Keys**: https://openrouter.ai/keys
