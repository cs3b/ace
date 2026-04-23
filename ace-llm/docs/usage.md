---
doc-type: how-to-guide
title: ace-llm Usage Guide
purpose: Usage guide for ace-llm CLI — querying providers, managing output, and handling errors.
ace-docs:
  last-updated: 2026-04-19
  last-checked: 2026-04-19
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
| `--interactive` / `--no-interactive` | | Start the provider's native interactive CLI instead of one-shot query | `false` |
| `--json` / `--no-json` | | Output command results as JSON | `false` |
| `--no-fallback` | | Disable provider fallback for this query | `false` |
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
| `gemini:flash-latest` | `gemini:gemini-2.5-flash` |
| `gemini:pro-latest` | `gemini:gemini-2.5-pro` |
| `codex:gpt` | `codex:gpt-5.4` |
| `codex:mini` | `codex:gpt-5.4-mini` |
| `codex:codex` | `codex:gpt-5.3-codex` |
| `codex:spark` | `codex:gpt-5.3-codex-spark` |
| `codex-gpt5` | `codex:gpt-5.4` |
| `codex-mini` | `codex:gpt-5.4-mini` |
| `sonnet` | `anthropic:s` -> `anthropic:claude-sonnet-4-5` |
| `opus` | `anthropic:o` -> `anthropic:claude-opus-4-5` |
| `haiku` | `anthropic:h` -> `anthropic:claude-haiku-4-5` |
| `grok` | `xai:grok-4` |

Preset suffixes can be applied with `@` or `--preset`:

```bash
ace-llm cc@ro "Summarize this diff"
ace-llm codex:gpt@yolo "Fix this bug"
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
ace-llm codex:gpt:high "Explain this architecture"
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

### Start an interactive CLI agent

```bash
ace-llm codex:gpt@yolo "/as-assign-drive abc123@010" --interactive
ace-llm claude:sonnet "/as-assign-drive abc123@010" --interactive
ace-llm pi:zai/glm-4.7 "/as-assign-drive abc123@010" --interactive
```

Interactive mode is for CLI-backed providers that support a native interactive UI. `ace-llm` still resolves aliases, model suffixes, presets, and skill translation before launching the provider.

In interactive mode:

- `codex` launches `codex` directly, not `codex exec`
- `claude` launches `claude` directly, not `claude -p`
- `pi` launches `pi` directly, not `pi -p`

Interactive mode rejects one-shot-only options such as `--output`, non-text `--format`, `--temperature`, and `--max-tokens`.

### List providers

```bash
ace-llm --list-providers
```

Output uses the format:

- `Available LLM Providers (filtered - X of Y active):`
- Provider rows with status and model count (for example `✓ google · 8 models (...)`)
- Per-provider setup hints (for example `Setup hint: set GEMINI_API_KEY or GOOGLE_API_KEY`)
- Optional `Inactive providers (N):` section

### Provider credential setup reference

Use `ace-llm --list-providers` as the canonical source of truth for active providers and setup hints.

### Check exact provider reachability

```bash
ace-llm gemini:pro "ping" --no-fallback --timeout 15 --max-tokens 4
ace-llm codex:mini "ping" --no-fallback --json --timeout 15 --max-tokens 4
```

Fallback is enabled by default through `llm.fallback`. Add `--no-fallback` when you want the result or failure to represent the requested provider/model rather than a configured fallback provider.

Common credential env keys:

| Provider | Typical env key(s) |
|----------|---------------------|
| `google` | `GEMINI_API_KEY` or `GOOGLE_API_KEY` |
| `openai` | `OPENAI_API_KEY` |
| `anthropic` | `ANTHROPIC_API_KEY` |
| `mistral` | `MISTRAL_API_KEY` |
| `togetherai` | `TOGETHER_API_KEY` or `TOGETHERAI_API_KEY` |

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
Unknown provider: <name>. Supported providers: <list>. Run `ace-llm --list-providers` for available providers and configuration guidance.
```

### Inactive provider

When provider exists but is filtered out:

```text
Provider '<name>' is inactive. It exists but is not in llm.providers.active.
To enable it, add '<name>' to llm.providers.active in your config.
Active providers: <list>
Run `ace-llm --list-providers` for available providers and configuration guidance.
```

## Runtime Help

```bash
ace-llm --help
```

## Package Verification

Run deterministic and scenario layers with the package contract:

```bash
ace-test ace-llm
ace-test ace-llm feat
ace-test ace-llm all
ace-test-e2e ace-llm
```

Coverage layout:
- `test/fast/` for deterministic package tests
- `test/feat/` for deterministic feature/CLI contract tests
- `test/e2e/` for retained scenario workflows only
