---
doc-type: user
title: ace-git-commit
purpose: Documentation for ace-git-commit/README.md
ace-docs:
  last-updated: 2026-03-21
  last-checked: 2026-03-21
---

# ace-git-commit

Turn diffs into clear, conventional commit messages — powered by LLM.

![ace-git-commit demo](docs/demo/ace-git-commit-getting-started.gif)

## Why ace-git-commit

Writing good commit messages takes time. `ace-git-commit` analyzes your diff and intent to generate conventional commit messages that explain *why*, not just *what*. It handles monorepo scoping automatically — split commits across packages with one command.

Same CLI for developers and coding agents. Same commit quality.

## Features

- **LLM-powered messages** — generates conventional commits from diffs using configurable models
- **Intention-aware** — pass `-i "fix auth bug"` to guide the message toward your intent
- **Monorepo scoping** — auto-detects package boundaries, splits into scoped commits
- **Split commits** — multi-package changes become separate, focused commits per scope
- **Dry-run mode** — preview generated messages without committing
- **Conventional format** — `type(scope): subject` with optional body, following project conventions
- **Configuration cascade** — gem defaults → project `.ace/` → user `~/.ace/` overrides

## Works with

- **[ace-git](../ace-git)** — git operations, diff analysis, and status management
- **[ace-llm](../ace-llm)** — LLM provider abstraction for message generation (supports Gemini, OpenAI, Anthropic, local)
- **[ace-support-config](../ace-support-config)** — configuration cascade for model and convention settings

## Agent Skills

- **`as-git-commit`** — generate intelligent commit message from staged or all changes

See [Handbook Reference](docs/handbook.md) for the complete catalog including the Conventional Commits guide and prompt templates.

## Documentation

- [Getting Started](docs/getting-started.md) — end-to-end tutorial
- [Usage Guide](docs/usage.md) — full command reference
- [Handbook Reference](docs/handbook.md) — skill, workflow, guide, prompts
- [Comparison Notes](COMPARISON.md) — migration from dev-tools
- Runtime help: `ace-git-commit --help`

## Part of ACE

`ace-git-commit` is part of [ACE](../README.md) (Agentic Coding Environment), a CLI-first toolkit for agent-assisted development.
