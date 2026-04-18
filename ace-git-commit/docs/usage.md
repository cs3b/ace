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
| `--model` | | Provider:model override (e.g. role:commit, gpt4, claude) |
| `--only-staged` | `-s` | Commit only already-staged files and keep unstaged edits untouched |
| `--dry-run` | `-n` | Preview message without committing |
| `--no-split` | | Disable automatic scope-based commit splitting (single commit across scopes) |
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

## Reproducible Split and No-Split Setup

Use package-level config to make split behavior explicit and reproducible:

```bash
mkdir -p pkg-a/.ace/git pkg-b/.ace/git

cat > pkg-a/.ace/git/commit.yml <<'YAML'
git:
  conventions:
    scope: pkg-a
YAML

cat > pkg-b/.ace/git/commit.yml <<'YAML'
git:
  conventions:
    scope: pkg-b
YAML
```

Then modify files in both packages:

- Default behavior: `ace-git-commit pkg-a pkg-b` creates per-scope commits when split conditions are met.
- Override behavior: `ace-git-commit --no-split pkg-a pkg-b` forces one commit containing both scopes.

## `--only-staged` Expected Git State

`--only-staged` uses the current index as the commit contract:

1. Stage one or more files with `git add`.
2. Leave other changes unstaged.
3. Run `ace-git-commit --only-staged`.

Expected outcome:
- The new commit contains only staged files.
- Unstaged modifications remain in `git status` after the commit.

## Configuration

Settings cascade: gem defaults → project `.ace/git/commit.yml` → user `~/.ace/git/commit.yml`.

```yaml
# .ace/git/commit.yml
git:
  model: role:commit
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

## Testing Contract

`ace-git-commit` uses the `fast` / `feat` / `e2e` model:

- `ace-test ace-git-commit` - default deterministic suite (`test/fast/`)
- `ace-test ace-git-commit feat` - deterministic feature/contract suite when present (`test/feat/`)
- `ace-test-e2e ace-git-commit` - scenario workflow suite (`test/e2e/`)
- `ace-test ace-git-commit all` - full package suite

## Runtime Help

```bash
ace-git-commit --help
```
