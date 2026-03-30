---
doc-type: user
title: Getting Started with ace-llm
purpose: Documentation for ace-llm/docs/getting-started.md
ace-docs:
  last-updated: 2026-03-22
  last-checked: 2026-03-22
---

# Getting Started with ace-llm

Use `ace-llm` to query multiple LLM providers from one CLI command.

## Prerequisites

- Ruby 3.2+
- At least one provider credential configured (for example `GEMINI_API_KEY`, `OPENAI_API_KEY`, or `ANTHROPIC_API_KEY`)

## Installation

Install from RubyGems:

```bash
gem install ace-llm
```

Or in this monorepo:

```bash
bundle install
```

## Your first query

Run a query with a built-in alias:

```bash
ace-llm gflash "Summarize the last commit in two bullets"
```

Use provider:model directly when needed:

```bash
ace-llm google:gemini-2.5-flash "Explain service objects in Ruby"
```

## Exploring providers and models

List configured providers and available models:

```bash
ace-llm --list-providers
```

If provider filters are active in config, output includes active and inactive provider sections.
Each provider row also includes setup hints so you can see required credential env vars quickly.

### Provider credential quick reference

Use `ace-llm --list-providers` first when setup fails. Common env vars:

| Provider | Env var(s) |
|----------|------------|
| `google` | `GEMINI_API_KEY` or `GOOGLE_API_KEY` |
| `openai` | `OPENAI_API_KEY` |
| `anthropic` | `ANTHROPIC_API_KEY` |

## Saving output and controlling format

Write responses to disk and choose output format:

```bash
ace-llm gflash "Create release notes" --output /tmp/release.md --format markdown
ace-llm gflash "Return structured JSON" --output /tmp/result.json --format json
```

## Setting up fallback chains

Configure fallback providers in `.ace/llm/config.yml`:

```yaml
llm:
  fallback:
    enabled: true
    retry_count: 3
    retry_delay: 1.0
    max_total_timeout: 30.0
    providers:
      - google:gemini-2.5-flash
      - anthropic:claude-sonnet-4-5
      - openai:gpt-5.1
```

Then run queries normally; `ace-llm` retries transient failures and falls back through the configured chain.

## Common Commands

| Command | What it does |
|---------|-------------|
| `ace-llm gflash "Hello"` | Query using a short alias |
| `ace-llm --list-providers` | Show active provider/model availability |
| `ace-llm google --model gemini-3-flash-preview --prompt "Hi"` | Select provider + explicit model |
| `ace-llm gflash --output /tmp/out.md --format markdown` | Save formatted output to file |
| `ace-llm gflash@ro "Review this diff"` | Run with preset suffix |

## Next steps

- [Usage Guide](usage.md) for full option and error reference
- [Handbook Reference](handbook.md) for package handbook assets
- Configure custom aliases and provider overrides in `.ace/llm/`
- Tune fallback and timeout behavior for your environment
