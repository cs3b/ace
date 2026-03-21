---
doc-type: user
title: ace-review
purpose: Documentation for ace-review/README.md
ace-docs:
  last-updated: 2026-03-21
  last-checked: 2026-03-21
---

# ace-review

Multi-model code review with preset-based analysis — for PRs, tasks, and packages.

![ace-review demo](docs/demo/ace-review-getting-started.gif)

## Why ace-review

Code review shouldn't depend on who's available or which model is trending. `ace-review` runs focused, repeatable reviews using configurable presets and multiple LLM models in parallel. Findings become trackable feedback items with a full verify → apply → resolve lifecycle.

Same CLI for developers and coding agents. Same review quality.

## Features

- **Multi-model execution** — run reviews across multiple LLMs in parallel, then synthesize findings
- **Preset-based** — focused presets for code quality, security, docs, PR review, and custom workflows
- **GitHub PR integration** — review PRs directly with `--pr`, optionally post comments back
- **Feedback lifecycle** — findings become draft → verified → pending → resolved/skipped items
- **Session artifacts** — every review is saved for traceability, follow-up, and audit
- **Prompt composition** — modular prompts for architecture, languages, quality focus, and format
- **Developer feedback** — include PR comments as review inputs alongside LLM analysis

## Works with

- **[ace-bundle](../ace-bundle)** — context loading for review presets and workflow instructions
- **[ace-git](../ace-git)** — diff analysis, commit ranges, and PR metadata
- **[ace-llm](../ace-llm)** — LLM provider abstraction for multi-model review execution
- **[ace-task](../ace-task)** — task-scoped reviews with context from behavioral specs

## Agent Skills

- **`as-review-run`** — review code changes with preset-based analysis and LLM feedback
- **`as-review-pr`** — review a GitHub PR with feedback verification and comment resolution
- **`as-review-package`** — comprehensive code, docs, UX/DX review with recommendations
- **`as-review-apply-feedback`** — apply verified feedback items from code review
- **`as-review-verify-feedback`** — verify feedback items through multi-dimensional claim analysis

See [Handbook Reference](docs/handbook.md) for the complete catalog including prompts and the code review guide.

## Documentation

- [Getting Started](docs/getting-started.md) — end-to-end tutorial
- [Usage Guide](docs/usage.md) — full command reference
- [Feedback Workflow](docs/feedback-workflow.md) — feedback lifecycle and CLI
- [Handbook Reference](docs/handbook.md) — skills, workflows, prompts, guide, template
- Runtime help: `ace-review --help`

## Part of ACE

`ace-review` is part of [ACE](../README.md) (Agentic Coding Environment), a CLI-first toolkit for agent-assisted development.
