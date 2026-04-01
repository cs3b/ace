---
doc-type: user
title: ace-review CLI Reference
purpose: Documentation for ace-review/docs/usage.md
ace-docs:
  last-updated: 2026-03-21
  last-checked: 2026-03-21
---

# ace-review CLI Reference

Complete command reference for `ace-review` and `ace-review-feedback`.

## Installation

```bash
gem install ace-review
```

## ace-review

### Synopsis

```
ace-review [OPTIONS]
```

### Review Options

| Option | Description |
|--------|-------------|
| `--preset` | Review preset: code, code-pr, security, performance, docs |
| `--pr` | Review GitHub PR (number, URL, or owner/repo#number) |
| `--subject` | Subject config (repeatable): `diff:range`, `diff:range -- path`, `files:glob`, `preset:name` |
| `--context` | Context config (preset name or YAML) |
| `--model` | LLM model(s) (repeatable for multi-model) |
| `--auto-execute` | Execute LLM query automatically |
| `--dry-run` | Prepare review without executing |

### PR Options

| Option | Description |
|--------|-------------|
| `--pr-comments` | Include PR comments as feedback source (default: true for --pr) |
| `--post-comment` | Post review as PR comment (requires --pr) |
| `--gh-timeout` | Timeout for gh CLI operations in seconds (default: 30) |

### Prompt Composition

| Option | Description |
|--------|-------------|
| `--prompt-base` | Base prompt module |
| `--prompt-format` | Format module |
| `--prompt-focus` | Focus modules (comma-separated) |
| `--add-focus` | Add focus modules to preset defaults |
| `--prompt-guidelines` | Guideline modules (comma-separated) |

### Output Options

| Option | Description |
|--------|-------------|
| `--output-dir` | Custom output directory |
| `--output` | Specific output file path |
| `--no-feedback` | Skip feedback extraction |
| `--feedback-model` | Model for feedback extraction |
| `--save-session` | Save session files (default: true) |
| `--session-dir` | Custom session directory |

### Informational

| Option | Description |
|--------|-------------|
| `--list-presets` | List available review presets |
| `--list-prompts` | List available prompt modules |
| `--version` | Show version |

### Global Options

| Flag | Description |
|------|-------------|
| `-q`, `--quiet` | Suppress non-essential output |
| `-v`, `--verbose` | Show verbose output |
| `-d`, `--debug` | Show debug output |
| `--help` | Show help |

### Examples

```bash
# Review current branch diff with code preset
ace-review --preset code --subject diff:origin/main..HEAD --auto-execute

# Review only selected paths from the branch diff
ace-review --preset code --subject "diff:origin/main...HEAD -- ace-test-runner-e2e" --auto-execute

# Review a GitHub PR
ace-review --pr 123 --auto-execute

# PR review with security focus
ace-review --pr 123 --preset security --auto-execute

# Multi-model review
ace-review --preset code --model gemini:pro --model openai:gpt4 --auto-execute

# Post review back to GitHub
ace-review --pr 123 --post-comment --auto-execute

# Preview without executing
ace-review --preset code --subject diff:HEAD~3 --dry-run

# List available presets and prompts
ace-review --list-presets
ace-review --list-prompts
```

## ace-review-feedback

Manage feedback items extracted from reviews.

### Subcommands

| Command | Description |
|---------|-------------|
| `ace-review-feedback list` | List feedback items (filter by `--status draft\|pending\|done`) |
| `ace-review-feedback show <id>` | Show full details of a feedback item |
| `ace-review-feedback verify <id>` | Verify: `--valid`, `--invalid`, or `--skip` with `--research` |
| `ace-review-feedback resolve <id>` | Mark as resolved with `--resolution` message |
| `ace-review-feedback skip <id>` | Skip with `--reason` |

### Feedback Examples

```bash
# List unverified items
ace-review-feedback list --status draft

# List verified items ready to fix
ace-review-feedback list --status pending

# Show details
ace-review-feedback show abc123

# Verify as valid
ace-review-feedback verify abc123 --valid --research "Confirmed at line 42"

# Mark as false positive
ace-review-feedback verify abc123 --invalid --research "Handled by middleware"

# Mark as resolved after fixing
ace-review-feedback resolve abc123 --resolution "Fixed in commit def456"

# Skip with reason
ace-review-feedback skip abc123 --reason "Design: intentional choice"
```

## Common Commands

| Command | What it does |
|---------|-------------|
| `ace-review --pr 123 --auto-execute` | Review a GitHub PR |
| `ace-review --list-presets` | List available presets |
| `ace-review --preset code --subject diff:origin/main..HEAD --auto-execute` | Review branch diff |
| `ace-review-feedback list --status pending` | List verified findings |
| `ace-review-feedback resolve <id>` | Mark finding as fixed |

## Runtime Help

```bash
ace-review --help
ace-review-feedback --help
```
