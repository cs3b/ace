---
doc-type: user
title: ace-prompt-prep Usage
purpose: CLI reference for ace-prompt-prep
ace-docs:
  last-updated: 2026-03-22
  last-checked: 2026-03-22
---

# ace-prompt-prep Usage

Command reference for prompt workspace setup, processing, enhancement, and context.

## Quick Start

```bash
ace-prompt-prep setup
ace-prompt-prep process
ace-prompt-prep --version
```

## Testing Contract

```bash
ace-test ace-prompt-prep
ace-test ace-prompt-prep feat
ace-test ace-prompt-prep all
ace-test-e2e ace-prompt-prep
```

## Commands

### `setup`

Create or reset the prompt workspace.

```bash
ace-prompt-prep setup [--template <name|uri>] [--task <task-id>] [--no-archive]
```

Options:

- `--template`, `-t` — Template name (`bug`) or URI (`tmpl://the-prompt-bug`)
- `--no-archive` / `--force`, `-f` — Skip archiving existing `the-prompt.md`
- `--task VALUE` — Use a task-specific prompt folder
- `--quiet`, `-q` / `--verbose`, `-v` / `--debug`, `-d`

Examples:

```bash
ace-prompt-prep setup
ace-prompt-prep setup --template bug
ace-prompt-prep setup --task 121
ace-prompt-prep setup --force
```

### `process`

Process prompt from workspace, archive, and output.

```bash
ace-prompt-prep process [--output FILE] [--bundle|--no-bundle] [--enhance] [--model VALUE] [--system-prompt PATH] [--task VALUE]
```

Options:

- `--output`, `-o` — Write output file, use `-` for explicit stdout (default)
- `--bundle`, `-b` — Enable context processing via `ace-bundle`
- `--no-bundle` — Disable context processing
- `--enhance`, `-e` — Run LLM enhancement
- `--no-enhance` — Disable LLM enhancement (overrides config)
- `--model VALUE` — LLM model
- `--system-prompt VALUE` — Custom system prompt path/URI
- `--task VALUE` — Use task prompt directory (e.g., `121`, `121.01`)
- `--quiet`, `-q` / `--verbose`, `-v` / `--debug`, `-d`

Examples:

```bash
ace-prompt-prep process
ace-prompt-prep process --output /tmp/prompt.md
ace-prompt-prep process --output -
ace-prompt-prep process --bundle
ace-prompt-prep process --no-bundle
ace-prompt-prep process --enhance
ace-prompt-prep process --enhance --model claude
ace-prompt-prep process --task 121
ace-prompt-prep process --task 121.01
```

### `version`

```bash
ace-prompt-prep version
ace-prompt-prep --version
```

## Context Loading (`bundle`)

Context is enabled when using `--bundle` or when config sets `bundle.enabled: true`.

Use frontmatter in the prompt file to define context sources:

```markdown
---
bundle:
  enabled: true
  sources:
    - file: docs/architecture.md
    - preset: project-overview
    - command: git status --short
---
```

## Configuration

Configuration path:

```text
.ace/prompt-prep/config.yml
```

Template path examples:

- `--template bug`
- `tmpl://the-prompt-bug`
- `--template tmpl://the-prompt-bug`

## File Layout

```text
.ace-local/prompt-prep/prompts/
  the-prompt.md
  _previous.md
  archive/
```

Archive file names are compact Base36 IDs in `archive/`.

## Version and Exit Codes

```bash
ace-prompt-prep version
ace-prompt-prep --version
```

- `0` — Success
- `1` — Error
