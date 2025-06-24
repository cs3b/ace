# LLM Query Guide

This comprehensive guide covers the unified `llm-query` command for interacting with Large Language Models (LLMs) across multiple providers using consistent syntax and options.

## Table of Contents

1. [Introduction](#introduction)
2. [Unified Syntax](#unified-syntax)
3. [Supported Providers](#supported-providers)
4. [Basic Usage](#basic-usage)
5. [Advanced Options](#advanced-options)
6. [Provider-Specific Information](#provider-specific-information)
7. [Model Management](#model-management)
8. [Error Handling](#error-handling)
9. [Best Practices](#best-practices)
10. [Troubleshooting](#troubleshooting)

---

## Introduction

The `exe/llm-query` command provides a unified interface for querying multiple LLM providers using consistent syntax. Instead of learning separate commands for each provider, you can use one command with a simple `provider:model` syntax.

**Key Benefits:**
- **Unified Interface**: One command for all providers
- **Consistent Options**: Same flags work across all providers
- **Model Flexibility**: Easy switching between providers and models
- **Future-Proof**: New providers integrate seamlessly

## Unified Syntax

### Basic Format

```bash
llm-query <provider>:<model> "<prompt>" [OPTIONS]
```

### Examples

```bash
# Google Gemini
llm-query google:gemini-2.5-flash "What is Ruby programming?"

# Anthropic Claude
llm-query anthropic:claude-4-0-sonnet-latest "Explain quantum computing"

# OpenAI GPT
llm-query openai:gpt-4o "Write a Ruby script"

# Provider only (uses default model)
llm-query google "Quick question"

# Using aliases
llm-query gflash "Fast response needed"
```

### Validation Rules

- **Provider**: Case-insensitive, must be supported
- **Model**: Case-sensitive, must be available for the provider
- **Syntax**: Exactly one colon (`:`) separator required
- **Components**: Neither provider nor model can be empty

## Supported Providers

### 1. Google (`google`)

**Setup:**
```bash
export GOOGLE_API_KEY="your-api-key-here"
```

**Available Models:**
- `gemini-2.5-flash` (default) - Fast, versatile model
- `gemini-2.5-pro` - Most capable Gemini model
- `gemini-2.0-flash-lite` - Lightweight version
- `gemini-1.5-pro` - Previous generation pro model
- `gemini-1.5-flash` - Previous generation flash model

**Best For:** General-purpose tasks, multimodal capabilities, fast responses

### 2. Anthropic (`anthropic`)

**Setup:**
```bash
export ANTHROPIC_API_KEY="your-api-key-here"
```

**Available Models:**
- `claude-4-0-sonnet-latest` (default) - Most intelligent Claude
- `claude-4-0-opus-latest` - Most powerful Claude
- `claude-3-5-sonnet-20241022` - Balanced performance
- `claude-3-5-haiku-20241022` - Fast and cost-effective

**Best For:** Long context tasks, nuanced responses, safety-critical applications

### 3. OpenAI (`openai`)

**Setup:**
```bash
export OPENAI_API_KEY="your-api-key-here"
```

**Available Models:**
- `gpt-4o` (default) - Most capable OpenAI model
- `gpt-4o-mini` - Faster, cheaper GPT-4 variant
- `o3` - Advanced reasoning model
- `o1` - Reasoning model
- `gpt-4-turbo` - Previous generation turbo model

**Best For:** Advanced reasoning, code generation, general tasks

### 4. Mistral (`mistral`)

**Setup:**
```bash
export MISTRAL_API_KEY="your-api-key-here"
```

**Available Models:**
- `mistral-large` (default) - Most capable Mistral model
- `mistral-medium` - Balanced performance
- `mistral-small` - Fast and cost-effective
- `codestral` - Specialized for code

**Best For:** Multilingual tasks, European AI compliance, code generation

### 5. Together AI (`together_ai`)

**Setup:**
```bash
export TOGETHER_API_KEY="your-api-key-here"
```

**Available Models:**
- `meta-llama/Meta-Llama-3.1-70B-Instruct-Turbo` (default)
- `meta-llama/Meta-Llama-3.1-8B-Instruct-Turbo`
- `mistralai/Mistral-8x7B-Instruct-v0.1`
- `deepseek-ai/deepseek-coder-33b-instruct`

**Best For:** Open-source models, cost-effectiveness, specialized models

### 6. LM Studio (`lmstudio`)

**Setup:**
- Download and install LM Studio from https://lmstudio.ai/
- Start LM Studio and load a model
- Ensure it's running on `localhost:1234`

**Available Models:** Any model loaded in your local LM Studio instance

**Best For:** Privacy-sensitive tasks, offline usage, complete data control

## Basic Usage

### String Prompts

```bash
# Direct string prompt
llm-query google:gemini-2.5-flash "What is Ruby programming language?"

# Multi-word prompts (use quotes)
llm-query anthropic:claude-4-0-sonnet-latest "Explain the difference between Ruby and Python"
```

### File Prompts

```bash
# Read prompt from file (auto-detected)
llm-query openai:gpt-4o prompt.txt

# File paths work with any provider
llm-query lmstudio research_questions.md
```

### Provider Defaults

```bash
# Use provider's default model
llm-query google "Quick question"
llm-query anthropic "Analyze this text"
llm-query openai "Generate code"
```

### Shorthand Aliases

```bash
# Common model aliases
llm-query gflash "Fast response"     # google:gemini-2.5-flash
llm-query csonet "Complex analysis" # anthropic:claude-4-0-sonnet-latest
llm-query o4mini "Quick task"       # openai:gpt-4o-mini
```

## Advanced Options

### Output Formatting

```bash
# JSON output (structured data)
llm-query google:gemini-2.5-flash "List programming languages" --format json

# Markdown output
llm-query anthropic:claude-4-0-sonnet-latest "Write a tutorial" --format markdown

# Plain text (default)
llm-query openai:gpt-4o "Explain AI" --format text
```

### File Output

```bash
# Save to file (format inferred from extension)
llm-query google:gemini-2.5-flash "Write documentation" --output docs.md

# Specify format explicitly
llm-query openai:gpt-4o "Generate data" --output data.json --format json

# Multiple files
llm-query anthropic:claude-4-0-sonnet-latest prompt.txt --output analysis.md
```

### System Instructions

```bash
# Text system instruction
llm-query google:gemini-2.5-flash "Write code" --system "You are a senior Ruby developer"

# System instruction from file
llm-query openai:gpt-4o "Review code" --system instructions.md

# Provider-specific personas
llm-query anthropic:claude-4-0-sonnet-latest "Analyze data" --system "You are a data scientist with expertise in statistics"
```

### Generation Parameters

```bash
# Temperature (creativity control)
llm-query google:gemini-2.5-flash "Write a poem" --temperature 0.9  # More creative
llm-query openai:gpt-4o "Summarize facts" --temperature 0.1        # More focused

# Max tokens (output length control)
llm-query anthropic:claude-4-0-sonnet-latest "Brief summary" --max-tokens 100

# Timeout (request timeout)
llm-query together_ai:meta-llama/Meta-Llama-3.1-70B-Instruct-Turbo "Complex task" --timeout 60
```

### Debug Mode

```bash
# Enable debug output
llm-query google:gemini-2.5-flash "Test prompt" --debug

# Debug with file output
llm-query openai:gpt-4o prompt.txt --output result.md --debug
```

## Provider-Specific Information

### Google Gemini Specifics

**Temperature Range:** 0.0 - 2.0
**Context Window:** Up to 2M tokens
**Special Features:** Multimodal capabilities

```bash
# Optimized for speed
llm-query google:gemini-2.5-flash "Quick question" --max-tokens 50

# Optimized for quality
llm-query google:gemini-2.5-pro "Complex analysis" --temperature 0.3
```

### Anthropic Claude Specifics

**Temperature Range:** 0.0 - 1.0
**Context Window:** Up to 200k tokens
**Special Features:** Constitutional AI, safety-focused

```bash
# Long document analysis
llm-query anthropic:claude-4-0-sonnet-latest large_document.txt --max-tokens 4000

# Safety-critical tasks
llm-query anthropic:claude-4-0-opus-latest "Review code for security" --temperature 0.2
```

### OpenAI Specifics

**Temperature Range:** 0.0 - 2.0
**Context Window:** 128k tokens (varies by model)
**Special Features:** Advanced reasoning, function calling

```bash
# Creative tasks
llm-query openai:gpt-4o "Write a story" --temperature 1.5

# Analytical tasks
llm-query openai:o3 "Solve this problem" --temperature 0.0
```

### Together AI Specifics

**Temperature Range:** 0.0 - 2.0
**Cost:** Very competitive for open-source models
**Special Features:** Access to latest open-source models

```bash
# Code generation with specialized model
llm-query together_ai:deepseek-ai/deepseek-coder-33b-instruct "Write a function"

# Fast inference
llm-query together_ai:meta-llama/Meta-Llama-3.1-8B-Instruct-Turbo "Quick response"
```

### LM Studio Specifics

**Cost:** Free (local inference)
**Privacy:** Complete data control
**Performance:** Depends on local hardware

```bash
# Use whatever model is loaded
llm-query lmstudio "Private query"

# Works offline
llm-query lmstudio:local-model "No internet needed"
```

## Model Management

### Discovering Models

```bash
# List models for each provider
exe/llm-models google
exe/llm-models anthropic
exe/llm-models openai
exe/llm-models mistral
exe/llm-models together_ai
exe/llm-models lmstudio

# Filter models
exe/llm-models google --filter flash
exe/llm-models openai --filter gpt-4

# JSON output for scripting
exe/llm-models anthropic --format json
```

### Model Selection Strategy

```bash
# Speed-optimized
llm-query google:gemini-2.5-flash "Quick task"
llm-query anthropic:claude-3-5-haiku-20241022 "Fast response"
llm-query openai:gpt-4o-mini "Simple question"

# Quality-optimized
llm-query google:gemini-2.5-pro "Complex analysis"
llm-query anthropic:claude-4-0-sonnet-latest "Detailed review"
llm-query openai:gpt-4o "Advanced reasoning"

# Cost-optimized
llm-query together_ai:meta-llama/Meta-Llama-3.1-8B-Instruct-Turbo "Budget task"
llm-query lmstudio "Free local inference"
```

## Error Handling

### Common Error Types

**Invalid Provider:**
```
Error: Unknown provider 'invalid'. Supported providers: google, anthropic, openai, mistral, together_ai, lmstudio
```

**Invalid Model:**
```
Error: Unknown model 'invalid-model' for provider 'google'
```

**Authentication:**
```
Error: API key not found. Set GOOGLE_API_KEY environment variable
```

**Rate Limiting:**
```
Error: Rate limit exceeded. Please wait before retrying
```

### Error Recovery

```bash
# Check available providers and models
llm-query --help

# Verify API key
echo $GOOGLE_API_KEY

# Test with debug mode
llm-query google:gemini-2.5-flash "test" --debug

# Use different provider as fallback
llm-query anthropic:claude-4-0-sonnet-latest "backup query"
```

## Best Practices

### Model Selection

1. **Speed vs Quality Trade-off:**
   - Fast: `gemini-2.5-flash`, `claude-3-5-haiku`, `gpt-4o-mini`
   - Balanced: `gemini-2.5-pro`, `claude-4-0-sonnet-latest`, `gpt-4o`
   - Maximum Quality: `claude-4-0-opus-latest`, `o3`

2. **Cost Optimization:**
   - Use smaller models for simple tasks
   - Limit `--max-tokens` for cost control
   - Consider Together AI for budget-conscious projects

3. **Privacy Considerations:**
   - Use LM Studio for sensitive data
   - Check provider data policies
   - Consider geographic data residency

### Temperature Guidelines

```bash
# Factual tasks (low temperature)
llm-query google:gemini-2.5-flash "What is the capital of France?" --temperature 0.1

# Balanced tasks (medium temperature)
llm-query anthropic:claude-4-0-sonnet-latest "Explain machine learning" --temperature 0.7

# Creative tasks (high temperature)
llm-query openai:gpt-4o "Write a creative story" --temperature 1.2
```

### System Instructions

```bash
# Be specific about the role
llm-query google:gemini-2.5-flash "Review code" --system "You are a senior software engineer specializing in Ruby. Focus on best practices, potential bugs, and performance issues."

# Provide context
llm-query anthropic:claude-4-0-sonnet-latest "Analyze data" --system "You are analyzing e-commerce data for a retail company. Focus on actionable insights for increasing sales."

# Set output format expectations
llm-query openai:gpt-4o "Generate report" --system "Provide your response in markdown format with clear headings and bullet points."
```

## Troubleshooting

### Environment Issues

```bash
# Check all API keys
env | grep API_KEY

# Test specific provider
llm-query google:gemini-2.5-flash "test" --debug
llm-query anthropic:claude-4-0-sonnet-latest "test" --debug

# Verify LM Studio connection
curl http://localhost:1234/v1/models
```

### Performance Issues

```bash
# Use faster models
llm-query google:gemini-2.5-flash "quick question"
llm-query anthropic:claude-3-5-haiku-20241022 "fast response"

# Reduce output length
llm-query openai:gpt-4o "brief answer" --max-tokens 100

# Increase timeout for complex tasks
llm-query anthropic:claude-4-0-sonnet-latest "complex analysis" --timeout 120
```

### Output Issues

```bash
# Force specific format
llm-query google:gemini-2.5-flash "data" --format json

# Check file permissions
llm-query openai:gpt-4o "content" --output /tmp/test.md

# Debug output processing
llm-query anthropic:claude-4-0-sonnet-latest "test" --output result.txt --debug
```

### Provider Fallbacks

```bash
#!/bin/bash
# Script with provider fallbacks

if llm-query google:gemini-2.5-flash "$1" --output response.md 2>/dev/null; then
    echo "Google query successful"
elif llm-query anthropic:claude-4-0-sonnet-latest "$1" --output response.md 2>/dev/null; then
    echo "Fallback to Anthropic successful"
elif llm-query openai:gpt-4o "$1" --output response.md 2>/dev/null; then
    echo "Fallback to OpenAI successful"
else
    echo "All providers failed"
    exit 1
fi
```

## Migration from Old Commands

The following legacy commands are replaced by the unified syntax:

| Old Command | New Unified Command |
|-------------|-------------------|
| `llm-google-query "prompt"` | `llm-query google:gemini-2.5-flash "prompt"` |
| `llm-anthropic-query "prompt"` | `llm-query anthropic:claude-4-0-sonnet-latest "prompt"` |
| `llm-openai-query "prompt"` | `llm-query openai:gpt-4o "prompt"` |
| `llm-mistral-query "prompt"` | `llm-query mistral:mistral-large "prompt"` |
| `llm-lmstudio-query "prompt"` | `llm-query lmstudio "prompt"` |

All options (`--temperature`, `--max-tokens`, `--system`, etc.) work the same way with the new unified command.

---

*This guide covers the unified LLM query interface introduced in v0.2.0. For the latest updates and additional features, refer to the project's main documentation.*