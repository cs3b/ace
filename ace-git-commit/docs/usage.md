---
doc-type: user
title: ace-git-commit CLI Reference
purpose: Documentation for ace-git-commit/docs/usage.md
ace-docs:
  last-updated: 2026-03-21
  last-checked: 2026-03-21
---

# ace-git-commit CLI Reference

Complete command reference for `ace-git-commit`.

## Installation

```bash
gem install ace-git-commit
```

## Synopsis

```
ace-git-commit [FILES] [OPTIONS]
```

By default, stages ALL changes and generates a commit. Pass specific files to scope the commit.

## Options

| Option | Alias | Description |
|--------|-------|-------------|
| `--intention` | `-i` | Context hint for message generation (e.g. "fix auth bug") |
| `--message` | `-m` | Use this message directly instead of generating |
| `--model` | | Provider:model override (e.g. glite, gpt4, claude) |
| `--only-staged` | `-s` | Commit only already-staged files (don't auto-stage) |
| `--dry-run` | `-n` | Preview message without committing |
| `--no-split` | | Disable automatic scope-based commit splitting |
| `--force` | `-f` | Force commit (future use) |

### Global Options

| Flag | Description |
|------|-------------|
| `-q`, `--quiet` | Suppress non-essential output |
| `-v`, `--verbose` | Show verbose output |
| `-d`, `--debug` | Show debug output |
| `--version` | Show version |
| `--help` | Show help |

## Examples

```bash
# Commit all changes with auto-generated message
ace-git-commit

# Add intention for better message quality
ace-git-commit -i "fix auth bug"

# Commit specific files only
ace-git-commit ace-review/README.md ace-review/docs/getting-started.md

# Preview without committing
ace-git-commit --dry-run

# Only commit already-staged files
ace-git-commit --only-staged

# Use a specific model
ace-git-commit --model gpt4

# Provide explicit message (skip LLM)
ace-git-commit -m "fix(auth): handle expired tokens"

# Disable scope-based splitting in monorepo
ace-git-commit --no-split
```

## Configuration

Settings cascade: gem defaults → project `.ace/git/commit.yml` → user `~/.ace/git/commit.yml`.

```yaml
# .ace/git/commit.yml
git:
  model: glite
  conventions:
    format: conventional
    scopes:
      enabled: true
      detect_from_paths: true
```

## Common Commands

| Command | What it does |
|---------|-------------|
| `ace-git-commit` | Commit all changes with LLM-generated message |
| `ace-git-commit -i "..."` | Commit with intention context |
| `ace-git-commit --dry-run` | Preview message without committing |
| `ace-git-commit --only-staged` | Commit only staged files |
| `ace-git-commit path/ path/` | Commit specific files/dirs |

## Runtime Help

```bash
ace-git-commit --help
```
