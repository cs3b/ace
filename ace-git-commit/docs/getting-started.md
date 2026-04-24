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

## Setup failure recovery (first commit)

For the first ACE setup snapshot, prefer the deterministic direct-message path:

```bash
bundle exec ace-git-commit --only-staged --no-split -m "chore: set up ace tooling"
```

This is the reliable first-use path because it commits the current staged setup files without invoking LLM-backed
message generation.

If you try an LLM-backed setup commit first and provider credentials, model access, or local CLI readiness are not
ready yet, inspect the current staged state and then fall back to the deterministic command:

```bash
git status
bundle exec ace-llm --list-providers
bundle exec ace-config doctor
bundle exec ace-git-commit --only-staged --no-split -m "chore: set up ace tooling"
```

Use the flags as follows:

- `--only-staged` commits only the current index and preserves any unstaged edits.
- `--no-split` keeps the initial setup snapshot in one commit when setup touches multiple scopes such as root docs,
  config, and generated agent assets.
- `-m` bypasses LLM generation entirely.

After `bundle exec ace-config doctor` confirms readiness, provider-backed commit generation becomes optional. Preview it
without committing by running:

```bash
bundle exec ace-git-commit --dry-run -i "set up ace tooling"
```

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
