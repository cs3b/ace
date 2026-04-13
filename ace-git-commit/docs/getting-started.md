---
doc-type: user
title: Getting Started with ace-git-commit
purpose: Documentation for ace-git-commit/docs/getting-started.md
ace-docs:
  last-updated: 2026-03-21
  last-checked: 2026-03-21
---

# Getting Started with ace-git-commit

Use `ace-git-commit` to generate meaningful commit messages from your git diff with one command.

## Installation

```bash
gem install ace-git-commit
```

Requires Ruby 3.2+ and a configured LLM provider in your ACE setup (see [ace-llm](../ace-llm)).

## 1) Make your first commit message

Run:

```bash
ace-git-commit
```

By default, the tool stages changes and generates a conventional commit message from your diff.

## 2) Add intention for better context

Run:

```bash
ace-git-commit -i "fix auth bug"
```

Use `-i` to tell the model what you are trying to do so the message can prioritize intent, not only file changes.

## 3) Configure for your project

Create `.ace/git/commit.yml`:

```yaml
git:
  model: role:commit
```

You can keep project-level defaults in `.ace/` and override from your user config when needed.

## 4) Work in monorepos with scoped commits

Run:

```bash
ace-git-commit ace-review/README.md ace-review/docs/getting-started.md
```

When changes span multiple packages, `ace-git-commit` can split work by scope based on your config so commit history stays clean.

## Common Commands

| Command | What it does |
|---------|-------------|
| `ace-git-commit` | Commit all changes with LLM-generated message |
| `ace-git-commit -i "..."` | Commit with intention context |
| `ace-git-commit --dry-run` | Preview message without committing |
| `ace-git-commit --only-staged` | Commit only staged files |
| `ace-git-commit path/ path/` | Commit specific files/dirs |

## Run Package Tests

Use the restarted package test model:

- `ace-test ace-git-commit` for deterministic fast-loop tests
- `ace-test ace-git-commit feat` for deterministic feature/contract tests when present
- `ace-test-e2e ace-git-commit` for retained workflow scenarios
- `ace-test ace-git-commit all` for complete package verification

## What to try next

- [Usage Guide](usage.md) -- full command reference with all options
- [Handbook Reference](handbook.md) -- skill, workflow, Conventional Commits guide, prompts
- Runtime help: `ace-git-commit --help`
