---
doc-type: how-to-guide
title: ace-llm Usage Guide
purpose: Usage guide for ace-llm CLI — querying providers, managing output, and handling errors.
ace-docs:
  last-updated: 2026-03-23
  last-checked: 2026-03-23
---

# ace-llm Usage Guide

## Overview

`ace-llm` provides one command surface for API-backed and CLI-backed LLM providers.

## Quick Start

```bash
ace-llm gflash "What changed in this branch?"
ace-llm google:gemini-2.5-flash "Explain this function"
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
| `--format FORMAT` | `-f` | Output format: `text`, `json`, `markdown` | `text` |
| `--temperature FLOAT` | `-t` | Sampling temperature (0.0-2.0) | provider default |
| `--max-tokens INT` | `-m` | Maximum output tokens | provider default |
| `--system TEXT` | `-s` | Replace system prompt | none |
| `--system-append TEXT` | | Append to system prompt | none |
| `--preset NAME` | | Execution preset name | none |
| `--model MODEL` | | Override model for provider/alias input | none |
| `--prompt PROMPT` | | Explicit prompt text (overrides positional) | none |
| `--cli-args TEXT` | | Extra flags for CLI providers | none |
| `--timeout SECONDS` | | Request timeout in seconds | `120` |
| `--force` / `--no-force` | | Overwrite output path | `false` |
| `--quiet` / `--no-quiet` | `-q` | Suppress non-essential output | `false` |
| `--verbose` / `--no-verbose` | | Verbose output | `false` |
| `--debug` / `--no-debug` | | Debug output | `false` |
| `--version` / `--no-version` | | Show version information | `false` |
| `--list-providers` / `--no-list-providers` | | List available providers | `false` |

## Provider Aliases

Aliases resolve through provider configs and may evolve with provider sync updates.

Common aliases in current defaults:

| Alias | Resolution |
|-------|------------|
| `gflash` | `google:flash` -> `google:gemini-flash-latest` |
| `glite` | `google:lite` -> `google:gemini-flash-lite-latest` |
| `gpro` | `google:pro` -> `google:gemini-2.5-pro` |
| `sonnet` | `anthropic:s` -> `anthropic:claude-sonnet-4-5` |
| `opus` | `anthropic:o` -> `anthropic:claude-opus-4-5` |
| `haiku` | `anthropic:h` -> `anthropic:claude-haiku-4-5` |
| `grok` | `xai:grok-4` |

Preset suffixes can be applied with `@` or `--preset`:

```bash
ace-llm cc@ro "Summarize this diff"
ace-llm codex:gpt-5@yolo "Fix this bug"
ace-llm claude:sonnet "Review this file" --preset rw
```

Built-in presets for CLI providers:

| Preset | Meaning | Providers |
|--------|---------|-----------|
| `@ro` | Read-only | `claude`, `codex`, `gemini`, `opencode`, `pi` |
| `@rw` | Read-write | `claude`, `codex`, `gemini`, `opencode`, `pi` |
| `@yolo` | Full autonomy | `claude`, `codex`, `gemini`, `opencode`, `pi` |

Preset configs are loaded from `.ace-defaults/llm/presets/<provider>/<preset>.yml` and can be overridden in `.ace/llm/presets/`.

## Thinking Levels

Thinking levels control reasoning depth for CLI providers that support extended thinking. Append `:level` after the model:

```bash
ace-llm codex:gpt-5:high "Explain this architecture"
ace-llm claude:sonnet:low "Quick summary"
ace-llm codex:spark:medium@ro "Review this diff"
```

Supported providers and levels:

| Provider | Levels |
|----------|--------|
| `claude` | `low`, `medium`, `high`, `xhigh` |
| `codex` | `low`, `medium`, `high`, `xhigh` |

Level configs are loaded from `.ace-defaults/llm/thinking/<provider>/<level>.yml` and can be overridden in `.ace/llm/thinking/`.

## Common Scenarios

### Save response output

```bash
ace-llm gflash "Draft release notes" --output /tmp/release.md --format markdown
```

When writing to file, output is multiline and includes fields such as:

- `Response saved to: /tmp/release.md`
- `Provider: ...`
- `Execution time: ...`
- `Tokens: ...`

### List providers

```bash
ace-llm --list-providers
```

Output uses the format:

- `Available LLM Providers (filtered - X of Y active):`
- Provider rows with status and model count (for example `✓ google · 8 models (...)`)
- Optional `Inactive providers (N):` section

### Provider filtering

Configure provider allow-list in `.ace/llm/config.yml`:

```yaml
llm:
  providers:
    active:
      - google
      - anthropic
```

Temporary override via environment variable:

```bash
ACE_LLM_PROVIDERS_ACTIVE=google,anthropic ace-llm --list-providers
```

## Error Messages

### Unknown provider

When the provider name does not exist, error format includes:

```text
Unknown provider: <name>. Supported providers: <list>
```

### Inactive provider

When provider exists but is filtered out:

```text
Provider '<name>' is inactive. It exists but is not in llm.providers.active.
To enable it, add '<name>' to llm.providers.active in your config.
Active providers: <list>
```

## Runtime Help

```bash
ace-llm --help
```
