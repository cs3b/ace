---
doc-type: guide
title: ace-llm Query Reference Guide
purpose: Documentation for ace-llm/handbook/guides/llm-query-tool-reference.g.md
ace-docs:
  last-updated: 2026-04-23
  last-checked: 2026-04-23
---

# ace-llm Query Reference Guide

## Purpose

This guide summarizes the current `ace-llm` query surface for handbook consumers that need concise command patterns, alias behavior, and provider-specific notes.

## Command Surface

Use `ace-llm` to query API-backed and CLI-backed providers through one CLI:

```bash
ace-llm PROVIDER[:MODEL] [PROMPT] [options]
ace-llm PROVIDER --prompt PROMPT [options]
ace-llm PROVIDER PROMPT --model MODEL [options]
```

Examples:

```bash
ace-llm gflash "Summarize this branch"
ace-llm google:gemini-2.5-flash "Explain service objects in Ruby"
ace-llm codex:gpt:high "Review this architecture"
ace-llm codex:gpt@yolo "/as-assign-drive abc123@010" --interactive
```

## Common Patterns

### Aliases and explicit models

- Use aliases when you want stable shorthand such as `gflash`, `glite`, `sonnet`, or `codex:mini`.
- Use `provider:model` when you need an exact model target.
- Use `--model` when the provider is fixed but the model varies per call.

Examples:

```bash
ace-llm gflash "Quick summary"
ace-llm gemini:flash-latest "Check provider alias resolution"
ace-llm google --model gemini-3-flash-preview --prompt "Hi"
```

### Presets and thinking levels

- Append `@preset` to apply execution presets such as `@ro`, `@rw`, or `@yolo`.
- Append `:level` after the model for supported thinking providers such as `codex` and `claude`.

Examples:

```bash
ace-llm cc@ro "Summarize this diff"
ace-llm codex:gpt:high "Explain this architecture"
ace-llm claude:sonnet "Review this file" --preset rw
```

### Native interactive CLI sessions

Use `--interactive` when you want the provider's native terminal UI instead of one-shot output.

Examples:

```bash
ace-llm codex:gpt@yolo "/as-assign-drive abc123@010" --interactive
ace-llm claude:sonnet "/as-assign-drive abc123@010" --interactive
ace-llm pi:zai/glm-4.7 "/as-assign-drive abc123@010" --interactive
```

Interactive mode still resolves aliases, presets, and translated skill prompts before launching the provider CLI.

### Exact provider reachability

Fallback is enabled by default. Use `--no-fallback` when you want the requested target to succeed or fail directly rather than routing through configured fallback providers.

Examples:

```bash
ace-llm gemini:pro "ping" --no-fallback --timeout 15 --max-tokens 4
ace-llm codex:mini "ping" --no-fallback --json --timeout 15 --max-tokens 4
```

## High-Value Options

| Option | Purpose |
|--------|---------|
| `--output FILE` | Write response output to a file |
| `--format text|json|markdown` | Control output formatting |
| `--system TEXT` / `--system-append TEXT` | Set or extend system instructions |
| `--preset NAME` | Apply an execution preset |
| `--model MODEL` | Override model for a provider or alias input |
| `--timeout SECONDS` | Limit request time |
| `--max-tokens INT` | Limit output length |
| `--interactive` | Launch native CLI mode for supported providers |
| `--json` | Emit structured command results |
| `--no-fallback` | Disable configured fallback routing for this call |
| `--list-providers` | Show active providers, models, and setup hints |

## Provider Notes

### Google and Gemini families

- `google:*` targets API-backed Gemini models.
- `gemini:*` targets the Gemini CLI-backed provider from `ace-llm-providers-cli`.
- Current CLI alias examples:
  - `gemini:flash-latest` -> `gemini:gemini-3-flash-preview`
  - `gemini:pro-latest` -> `gemini:gemini-3.1-pro-preview`

### Codex and Claude families

- `codex` and `claude` support presets and thinking levels.
- `--interactive` launches their native terminal UI rather than one-shot execution.

### Provider discovery

Use `ace-llm --list-providers` as the canonical availability and setup check. The output includes active providers, model counts, inactive providers when filtered, and credential hints.

## Recommended Usage

- Prefer aliases for common workflows and explicit models for exact reproducibility.
- Use `--no-fallback` for diagnostics, setup checks, and doctor-style reachability tests.
- Use `--interactive` for agent-driving workflows and one-shot mode for scripting.
- Keep provider setup docs anchored on `ace-llm --list-providers` rather than hardcoded env-var lists when possible.

## Related Docs

- [Usage Guide](../../docs/usage.md)
- [Getting Started](../../docs/getting-started.md)
- [Handbook Reference](../../docs/handbook.md)
