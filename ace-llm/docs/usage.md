---
doc-type: how-to-guide
title: ace-llm Usage Guide
purpose: Usage guide for ace-llm CLI — querying LLM providers, provider filtering, and configuration.
ace-docs:
  last-updated: 2026-03-18
  last-checked: 2026-03-21
---

# ace-llm Usage Guide

## Document Type: How-To Guide + Reference

## Overview

`ace-llm` provides a unified CLI interface for querying LLM providers. It supports direct API providers (Anthropic, Google, OpenAI, etc.) and CLI-based providers (Claude Code, Codex, Gemini CLI).

**Key Features:**
- Single command for all LLM providers
- Short aliases for common provider/model combinations
- Provider allow-list filtering via config or environment variable
- Output to file with format control (text, json, markdown)
- Preset-based configuration for repeatable query patterns

## Quick Start

```bash
# Query using a short alias
ace-llm gflash "What is Ruby?"

# Query with explicit provider:model
ace-llm google:gemini-2.5-flash "Explain monads"

# List available providers
ace-llm --list-providers
```

## Command Interface

### Syntax

```bash
ace-llm PROVIDER[:MODEL] [PROMPT] [options]
ace-llm PROVIDER --prompt PROMPT [options]
ace-llm PROVIDER PROMPT --model MODEL [options]
```

### Options

| Option | Short | Description | Default |
|--------|-------|-------------|---------|
| `--output FILE` | `-o` | Write response to file | stdout |
| `--format FORMAT` | `-f` | Output format: text, json, markdown | text |
| `--temperature FLOAT` | `-t` | Sampling temperature (0.0–2.0) | provider default |
| `--max-tokens INT` | `-m` | Maximum output tokens | provider default |
| `--system TEXT` | `-s` | System prompt text or file path | none |
| `--system-append TEXT` | | Append text to system prompt | none |
| `--preset NAME` | | Named execution preset | none |
| `--model MODEL` | | Override model (when using alias or provider only) | none |
| `--prompt PROMPT` | | Prompt text (overrides positional arg) | none |
| `--cli-args TEXT` | | Extra flags for CLI providers | none |
| `--timeout SECONDS` | | Request timeout | provider default |
| `--force` | | Overwrite existing output file | false |
| `--quiet` | `-q` | Suppress config summary | false |
| `--debug` | `-d` | Enable debug output | false |
| `--list-providers` | | List available providers | — |

## Provider Aliases

Short aliases expand to `PROVIDER:MODEL`:

| Alias | Expands To |
|-------|-----------|
| `gflash` | `google:gemini-2.5-flash` |
| `glite` | `google:gemini-2.0-flash-lite` |
| `gpt4` | `openai:gpt-4` |
| `claude` | `anthropic:claude-3-5-sonnet` |

Combine with a preset using `@`:

```bash
ace-llm gflash@ro "Summarize this diff"
ace-llm codex:gpt-5:high@ro "Review this code"
```

`@ro` is the ace-llm read-only execution preset. It is provider-specific and is not a
generic alias for native provider "plan" modes.

`@prompt` is the prompt-only execution preset when a provider has a verified no-tools
mode. At the moment, `claude:*@prompt` is supported; other CLI providers may not expose
an enforceable no-tools mode yet.

## Common Scenarios

### Scenario 1: Simple query

**Goal**: Ask a quick question and print the response.

```bash
ace-llm gflash "What is the difference between a process and a thread?"
```

**Expected output:**
```
[Config summary shown unless --quiet]
A process is an independent program...
```

### Scenario 2: Save response to file

**Goal**: Write the LLM response to a file for later use.

```bash
ace-llm claude:sonnet "Summarize this diff" --output /tmp/summary.md --format markdown
```

**Expected output:**
```
Response saved to /tmp/summary.md (markdown, 847 tokens)
```

### Scenario 3: Use a system prompt

**Goal**: Apply a system instruction to shape the response.

```bash
ace-llm gflash "Review this code" \
  --system "You are a senior Ruby developer. Be concise and actionable." \
  --output /tmp/review.md
```

### Scenario 4: CLI provider with extra flags

**Goal**: Pass provider-specific flags to CLI-based providers like Claude Code.

```bash
ace-llm claude:sonnet "Hello" --cli-args "dangerously-skip-permissions"
ace-llm claude:sonnet "Hi" --cli-args "--model=claude-sonnet-4-0 --verbose"
```

### Scenario 5: List available providers

**Goal**: See which providers are configured and available.

```bash
ace-llm --list-providers
```

**Expected output (no filter):**
```
Available LLM Providers:

✓ anthropic (API key configured)
  Models: claude-3-5-sonnet, claude-3-haiku

✓ google (API key configured)
  Models: gemini-2.5-flash, gemini-2.0-flash-lite

✗ openai (API key required)
  Models: gpt-4, gpt-4o-mini
...
```

## Provider Allow-List Filtering

Restrict which providers are active for listing, alias resolution, and query execution.

### Configure via project config

Create or update `.ace/llm/config.yml`:

```yaml
llm:
  providers:
    active:
      - google
      - anthropic
```

```bash
ace-llm --list-providers
```

**Expected output (filter active):**
```
Available LLM Providers (filtered - 2 of 26 active):

✓ anthropic (API key configured)
  Models: claude-3-5-sonnet, claude-3-haiku

✓ google (API key configured)
  Models: gemini-2.5-flash, gemini-2.0-flash-lite

Inactive providers (24):
  claude, codex, deepseek, gemini, mistral, openai, ...
```

### Override via environment variable

The `ACE_LLM_PROVIDERS_ACTIVE` environment variable overrides the config file (highest precedence):

```bash
# Single provider for a one-off run
ACE_LLM_PROVIDERS_ACTIVE=google ace-llm gflash "Hello"

# Multiple providers (comma-separated)
ACE_LLM_PROVIDERS_ACTIVE=google,anthropic ace-llm --list-providers

# Empty value disables filtering (use all providers)
ACE_LLM_PROVIDERS_ACTIVE= ace-llm --list-providers
```

### No filter (backward compatible default)

When `llm.providers.active` is absent or empty, all providers are active — identical to behavior before v0.26.0:

```yaml
# Either of these means "no filter"
llm:
  providers:
    active: []   # empty list = no filter

# Or simply omit the key entirely
```

### Provider name normalization

Provider names are normalized before matching: lowercased, hyphens and underscores stripped.

```yaml
# All equivalent in allow-list:
active:
  - google
  - Google
  - google-cloud   # normalized to "googlecloud"
```

Use `ace-llm --list-providers` to see the canonical normalized names.

### Inactive vs unknown provider errors

When a filter is active, querying a provider gives a distinct error based on its status:

**Inactive provider** (configured but filtered out):
```bash
ACE_LLM_PROVIDERS_ACTIVE=google ace-llm anthropic:claude "Hello"
# Error: Provider 'anthropic' is inactive (configured but not in llm.providers.active).
# To enable it, add 'anthropic' to llm.providers.active in your config.
# Active providers: google
```

**Unknown provider** (not configured at all):
```bash
ace-llm nonexistent:model "Hello"
# Error: Provider 'nonexistent' not found.
# Available providers: anthropic, google, openai, ...
```

## Configuration

### Config file locations (cascade order, highest to lowest priority)

1. CLI flags (immediate override)
2. Project `.ace/llm/config.yml` (committed to repo)
3. User `~/.ace/llm/config.yml` (personal preferences)
4. Gem `.ace-defaults/llm/config.yml` (built-in defaults)

### Example project config

```yaml
# .ace/llm/config.yml
llm:
  providers:
    active:
      - google
      - anthropic
```

### Environment variables

| Variable | Description |
|----------|-------------|
| `ACE_LLM_PROVIDERS_ACTIVE` | Comma-separated allow-list (overrides config). Empty = no filter. |

## Troubleshooting

### Problem: Provider not found

**Symptom**: `Error: Provider 'X' not found`

**Solution**: Check the provider is configured and name is spelled correctly.
```bash
ace-llm --list-providers   # see what's available
```

### Problem: Provider is inactive

**Symptom**: `Error: Provider 'X' is inactive`

**Solution**: Add the provider to your allow-list or clear the filter.
```bash
# Add to .ace/llm/config.yml
llm:
  providers:
    active:
      - X
      - other-provider

# Or temporarily bypass filter
ACE_LLM_PROVIDERS_ACTIVE= ace-llm X:model "prompt"
```

### Problem: Unknown provider in allow-list warning

**Symptom**: `Unknown providers in llm.providers.active: foo (ignored)`

**Solution**: Check spelling. Use `ace-llm --list-providers` to see valid names and their normalized forms.

### Problem: Output file already exists

**Symptom**: Error writing to `--output` path.

**Solution**: Use `--force` to overwrite, or choose a different path.
```bash
ace-llm gflash "prompt" --output /tmp/out.md --force
```

## Best Practices

1. **Use the allow-list in project config** to prevent accidental use of unapproved providers in team repos.
2. **Use aliases** (`gflash`, `glite`) for interactive use; use `provider:model` explicitly in scripts for clarity.
3. **Use `--quiet`** in automated workflows to suppress the config summary.
4. **Use `--output` with `--format markdown`** when saving review or summary responses for further processing.
5. **Use `ACE_LLM_PROVIDERS_ACTIVE`** for temporary overrides without touching config files.