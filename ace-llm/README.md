---
doc-type: user
title: ace-llm
purpose: Documentation for ace-llm/README.md
ace-docs:
  last-updated: 2026-03-22
  last-checked: 2026-03-22
---

# ace-llm

Query any LLM from the terminal -- one interface for every provider.

<!-- Demo GIF: render docs/demo/ace-llm-getting-started.tape with VHS to generate the GIF -->

## Why ace-llm

`ace-llm` gives you one CLI for API providers and CLI providers, so you can stop juggling different tools and flags. Built-in aliases, fallback routing, and response formatting make it practical for daily developer and agent workflows.

## Works With

- **[ace-support-cli](../ace-support-cli)** - shared CLI command patterns and option handling
- **[ace-support-config](../ace-support-config)** - config cascade across defaults, user, and project
- **[ace-llm-providers-cli](../ace-llm-providers-cli)** - provider bridge for CLI-based model execution

## Agent Skills

`ace-llm` currently ships no package-owned skills. Use runtime help and package docs directly.

## Features

- **Unified provider interface** - query many providers through one command surface
- **Alias-first workflows** - use short model aliases for fast prompting
- **Fallback and retries** - route around transient provider failures
- **Output controls** - save responses in text, markdown, or JSON
- **Preset support** - apply repeatable execution profiles with `@preset` or `--preset`
- **Cost and token reporting** - inspect usage metadata in response summaries

## Documentation

- [Getting Started](docs/getting-started.md) - tutorial flow for first query to fallback
- [Usage Guide](docs/usage.md) - command reference and operational examples
- [Handbook Reference](docs/handbook.md) - package handbook assets
- Runtime help: `ace-llm --help`

## Part of ACE

`ace-llm` is part of [ACE](../README.md) (Agentic Coding Environment), a CLI-first toolkit for agent-assisted development.
