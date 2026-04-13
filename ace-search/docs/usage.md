---
doc-type: user
title: ace-search CLI Reference
purpose: Documentation for ace-search/docs/usage.md
ace-docs:
  last-updated: 2026-03-22
  last-checked: 2026-03-22
---

# ace-search CLI Reference

Complete command reference for `ace-search`.

## Synopsis

```bash
ace-search [PATTERN] [SEARCH_PATH] [OPTIONS]
```

## Search Type Detection

Auto mode (default) chooses file or content search from your pattern.

- File-like examples: `*.rb`, `**/*.js`
- Content-like examples: `TODO`, `class.*Manager`

Override detection with `--files` or `--content` when needed.

## Arguments

| Argument | Description |
|----------|-------------|
| `PATTERN` | Search pattern (file glob or content regex) |
| `SEARCH_PATH` | Optional path to limit scope |

## Options

### Search Mode

| Option | Alias | Description |
|--------|-------|-------------|
| `--type=VALUE` | `-t` | Search type (`file`, `content`, `hybrid`, `auto`) |
| `--files` | `-f` | Search for files only |
| `--content` | `-c` | Search file contents only |

### Pattern and Match Behavior

| Option | Alias | Description |
|--------|-------|-------------|
| `--case-insensitive` | `-i` | Case-insensitive search |
| `--whole-word` | `-w` | Match whole words only |
| `--multiline` | `-U` | Enable multiline matching |
| `--hidden` | | Include hidden files/directories |

### Context and Scope

| Option | Alias | Description |
|--------|-------|-------------|
| `--after-context=NUM` | `-A` | Show lines after each match |
| `--before-context=NUM` | `-B` | Show lines before each match |
| `--context=NUM` | `-C` | Show lines around each match |
| `--glob=GLOB` | `-g` | Include files by glob pattern |
| `--include=VALUE` | | Include only these paths/globs |
| `--exclude=VALUE` | `-e` | Exclude paths/globs |
| `--since=TIME` | | Include files modified since TIME |
| `--before=TIME` | | Include files modified before TIME |
| `--staged` | | Search staged files only |
| `--tracked` | | Search tracked files only |
| `--changed` | | Search changed files only |

### Output and Result Control

| Option | Alias | Description |
|--------|-------|-------------|
| `--json` | | JSON output |
| `--yaml` | | YAML output |
| `--count` | | Show match counts |
| `--files-with-matches` | `-l` | Only print filenames |
| `--max-results=NUM` | | Limit number of results |
| `--fzf` | | Use fzf for interactive selection |
| `--preset=NAME` | `-p` | Apply named search preset |

### Informational and Global

| Option | Alias | Description |
|--------|-------|-------------|
| `--version` | | Show version information |
| `--quiet` | `-q` | Suppress non-essential output |
| `--verbose` | `-v` | Show verbose output |
| `--debug` | `-d` | Show debug output |
| `--help` | `-h` | Show help |

## Examples

```bash
# Content search (DWIM)
ace-search TODO

# File search via glob (DWIM)
ace-search "*.rb"

# Explicit content mode
ace-search "class.*Manager" --content

# Search staged files only
ace-search "TODO" --staged

# Use preset
ace-search "TODO" --preset daily-scan

# JSON output
ace-search "TODO" --json
```

## Testing Commands

Use the package test lanes as:

- `ace-test ace-search`
- `ace-test ace-search feat`
- `ace-test ace-search all`
- `ace-test-e2e ace-search`

## Runtime Help

```bash
ace-search --help
```
