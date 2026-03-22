---
doc-type: user
title: ace-prompt-prep
purpose: Documentation for ace-prompt-prep/README.md
ace-docs:
  last-updated: 2026-03-22
  last-checked: 2026-03-22
---

# ace-prompt-prep

Prompt workspace with archiving, LLM enhancement, and context loading -- manage prompts like code.

![ace-prompt-prep demo](docs/demo/ace-prompt-prep-setup-enhance.gif)

## Why use ace-prompt-prep

- Write prompts in markdown and keep every revision.
- Archive every prompt automatically with compact IDs for easy history browsing.
- Enhance prompts with LLM before sending.
- Inject project context from files, presets, or command output.
- Keep task-specific prompts grouped by task ID.

## Works With

- `ace-task` / `ace-taskflow`
- `ace-bundle`
- `ace-llm`
- `ace-git`

## Agent Skills

- `as-prompt-prep` (package-owned)

## Features

- **Automatic archiving**
  - Every run stores prompt history and keeps `_previous.md` updated.
- **LLM enhancement**
  - Improve prompt quality with `--enhance` and model selection.
- **Context loading**
  - Add project context to prompts through `ace-bundle` integration.
- **Task-specific prompts**
  - Automatically switch to task prompt folders with `--task` or branch detection.

## Documentation

- [Getting Started](docs/getting-started.md)
- [CLI Reference](docs/usage.md)
- CLI Help: `ace-prompt-prep --help`

## Part of ACE

Part of the ACE package ecosystem for agent-aware developer tooling.
