# Provider:Model Syntax Specification

## Overview

The unified `llm-query` command uses a `provider:model` syntax to specify which LLM provider and model to use for queries. This document defines the syntax rules, validation requirements, and examples for all supported providers.

## Syntax Format

```
llm-query <provider>:<model> "<prompt>"
```

Where:
- `<provider>` is one of the supported provider names (case-insensitive)
- `<model>` is the model identifier for that provider
- `<prompt>` is the text prompt to send to the model

## Supported Providers

### 1. Google (`google`)

**Available Models:**
- `gemini-2.5-flash` (default)
- `gemini-2.5-pro`
- `gemini-2.0-flash-lite`
- `gemini-pro`

**Examples:**
```bash
llm-query google:gemini-2.5-flash "What is Ruby?"
llm-query google:gemini-2.5-pro "Explain quantum computing"
```

### 2. Anthropic (`anthropic`)

**Available Models:**
- `claude-4-0-sonnet-latest`
- `claude-4-0-opus-latest`
- `claude-3-5-sonnet`
- `claude-3-opus`

**Examples:**
```bash
llm-query anthropic:claude-4-0-sonnet-latest "Write a Ruby script"
llm-query anthropic:claude-4-0-opus-latest "Analyze this code"
```

### 3. OpenAI (`openai`)

**Available Models:**
- `gpt-4o`
- `gpt-4o-mini`
- `o3`
- `o1`
- `gpt-4-turbo`

**Examples:**
```bash
llm-query openai:gpt-4o "Generate test cases"
llm-query openai:o3 "Solve this problem"
```

### 4. Mistral (`mistral`)

**Available Models:**
- `mistral-large`
- `mistral-medium`
- `mistral-small`
- `codestral`

**Examples:**
```bash
llm-query mistral:mistral-large "Explain algorithms"
llm-query mistral:codestral "Review this code"
```

### 5. Together AI (`together_ai`)

**Available Models:**
- `meta-llama/Llama-3.2-90B-Vision-Instruct-Turbo`
- `meta-llama/Meta-Llama-3.1-405B-Instruct-Turbo`
- `Qwen/Qwen2.5-72B-Instruct-Turbo`

**Examples:**
```bash
llm-query together_ai:meta-llama/Llama-3.2-90B-Vision-Instruct-Turbo "Describe this image"
llm-query together_ai:meta-llama/Meta-Llama-3.1-405B-Instruct-Turbo "Write documentation"
```

### 6. LM Studio (`lmstudio`)

**Available Models:**
- Any model loaded in local LM Studio instance
- Model names are determined by what's currently loaded

**Examples:**
```bash
llm-query lmstudio:llama-3.2-3b "Local query"
llm-query lmstudio:codellama-7b "Code generation"
```

## Validation Rules

### Provider Validation
- Provider names are case-insensitive
- Must be one of: `google`, `anthropic`, `openai`, `mistral`, `together_ai`, `lmstudio`
- Invalid providers will show an error with list of valid providers

### Model Validation
- Model names are case-sensitive for most providers
- For LM Studio, validation is deferred to the local instance
- Invalid models will show provider-specific error with available models

### Syntax Validation
- Must contain exactly one colon (`:`) separator
- Provider name cannot be empty
- Model name cannot be empty
- No spaces allowed in provider:model specification

## Error Handling

### Invalid Provider
```
Error: Unknown provider 'invalid'. Valid providers are: google, anthropic, openai, mistral, together_ai, lmstudio
```

### Invalid Model
```
Error: Unknown model 'invalid-model' for provider 'google'. Valid models are: gemini-2.5-flash, gemini-2.5-pro, gemini-2.0-flash-lite, gemini-pro
```

### Invalid Syntax
```
Error: Invalid provider:model syntax 'google'. Expected format: <provider>:<model>
```

### Missing Components
```
Error: Provider cannot be empty in 'google:'
Error: Model cannot be empty in ':gemini-2.5-flash'
```

## Dynamic Shorthand Aliases

The following shorthand aliases automatically resolve to the latest/recommended models:

- `gflash` → `google:gemini-2.5-flash`
- `gpro` → `google:gemini-2.5-pro`
- `csonet` → `anthropic:claude-4-0-sonnet-latest`
- `copus` → `anthropic:claude-4-0-opus-latest`
- `o4mini` → `openai:gpt-4o-mini`
- `o3` → `openai:o3`

**Usage:**
```bash
gflash "Quick question"
# Equivalent to: llm-query google:gemini-2.5-flash "Quick question"
```

## Edge Cases

### Special Characters in Model Names
- Forward slashes (`/`) are allowed in model names (e.g., Together AI models)
- Hyphens (`-`) and underscores (`_`) are allowed
- Periods (`.`) are allowed for version numbers

### Case Sensitivity
- Provider names: case-insensitive (`Google`, `GOOGLE`, `google` all valid)
- Model names: case-sensitive (`gemini-2.5-flash` ≠ `Gemini-2.5-Flash`)

### Whitespace
- Leading/trailing whitespace in provider:model is trimmed
- Internal whitespace is not allowed

## Backward Compatibility

All existing provider-specific executables remain functional:
- `llm-google-query` → wraps `llm-query google:gemini-2.5-flash`
- `llm-anthropic-query` → wraps `llm-query anthropic:claude-4-0-sonnet-latest`
- `llm-openai-query` → wraps `llm-query openai:gpt-4o`
- `llm-mistral-query` → wraps `llm-query mistral:mistral-large`
- `llm-together-ai-query` → wraps `llm-query together_ai:meta-llama/Meta-Llama-3.1-405B-Instruct-Turbo`
- `llm-lmstudio-query` → wraps `llm-query lmstudio:<default-model>`
