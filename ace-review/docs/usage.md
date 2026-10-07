---
doc-type: user
title: ace-review CLI Reference
purpose: Documentation for ace-review/docs/usage.md
ace-docs:
  last-updated: 2026-04-12
  last-checked: 2026-04-12
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
| `--preset` | Review preset from the shipped catalog, such as code-valid, code-fit, integration, or docs |
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
| `--server` / `--default-server` | Select a configured forge server for a PR review |
| `--provider-timeout` | Timeout for forge operations in seconds (default: 30) |

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
| `--session-dir` | Fresh session directory; existing empty directories may be claimed once |

### Concurrent reviews and exact session selection

Each new review claims its own session before writing prompts or metadata. Automatic
sessions use `.ace-local/review/sessions/review-<id>` with an opaque suffix when a
name collides. Successful execution prints both the exported report and the actual
session directory. Same-clock reviews preserve separate reports and feedback.

```bash
bin/ace-review --preset code-valid --subject diff:BASE..HEAD --auto-execute
# Output includes: Session directory: /project/.ace-local/review/sessions/review-<id>
bin/ace-review-feedback list --session /project/.ace-local/review/sessions/review-<id>
# Output contains only this session's findings.
```

For manual feedback creation, pass the exact reported session path to
`bin/ace-review-feedback create --session PATH`. Single-model `review.md` and
multi-model reports are discovered within that directory. Published findings are
immutable; start a fresh review when findings already exist.

An explicit path must be absent or an unclaimed empty directory. A permanent claim
remains after success, failure or interruption. Reusing a claimed or nonempty path,
a regular file, or a symlink fails before reviewer execution and preserves existing
contents. Choose a fresh writable path after an allocation refusal:

```bash
bin/ace-review --preset code-valid --subject diff:BASE..HEAD --session-dir .ace-local/review/source-round-2
# Output includes: Review session prepared: .ace-local/review/source-round-2
```

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

Extraction requires an explicit `findings` array in the synthesis response.
A missing array, duplicate JSON key, or finding without a nonempty textual title
and description fails the entire extraction; valid findings are not published
as a partial replacement. For example, `{"findings":[{"title":"","finding":"Bug"}]}`
is an extraction failure, while `{"findings":[]}` is a completed empty extraction.
Neither a provider's successful exit nor empty extraction is an approval verdict.


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
| `ace-test ace-review` | Run deterministic fast checks |
| `ace-test ace-review feat` | Run deterministic feature checks |
| `ace-test ace-review all` | Run full deterministic package coverage |
| `ace-test-e2e ace-review` | Run retained workflow scenarios |

## Runtime Help

```bash
ace-review --help
ace-review-feedback --help
```
