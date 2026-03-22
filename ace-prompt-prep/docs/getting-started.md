---
doc-type: user
title: ace-prompt-prep Getting Started
purpose: Tutorial reference for ace-prompt-prep usage
ace-docs:
  last-updated: 2026-03-22
  last-checked: 2026-03-22
---

# Get Started with ace-prompt-prep

## Prerequisites

- Ruby 3.2+
- `ace-prompt-prep` installed (via Gemfile or `bundle exec`)
- Optional: `ace-bundle` for context support
- Optional: LLM API credentials if you use `--enhance`

## 1. Set up a prompt workspace

Create the workspace and seed `the-prompt.md`:

```bash
ace-prompt-prep setup
```

This creates `.ace-local/prompt-prep/prompts/` and prepares a prompt file.

If you are working on a task:

```bash
ace-prompt-prep setup --task 121
```

## 2. Write and process a prompt

Edit `.ace-local/prompt-prep/prompts/the-prompt.md`:

```markdown
Explain the top three risks in the new login flow.
```

Then process it:

```bash
ace-prompt-prep process
```

Or write output to a file:

```bash
ace-prompt-prep process --output /tmp/prompt.md
```

## 3. Enhance with LLM (optional)

Improve prompt quality before using it:

```bash
ace-prompt-prep process --enhance
```

Pick a specific model when needed:

```bash
ace-prompt-prep process --enhance --model claude
```

## 4. Add context from your project

Use frontmatter and let `ace-bundle` expand context:

```markdown
---
bundle:
  enabled: true
  sources:
    - file: docs/architecture.md
    - preset: project-overview
    - command: git status --short
---

Review this diff for architecture and test impact.
```

Enable or disable context at command level:

```bash
ace-prompt-prep process --bundle
ace-prompt-prep process --no-bundle
```

## 5. Use task-specific prompts

When working on a task, keep context isolated:

```bash
ace-prompt-prep process --task 121
ace-prompt-prep process --task 121.01
ace-prompt-prep setup --task 121
```

Enable branch-based auto-detection with `task.detection: true` in config.

## Common Commands

| Goal | Command |
| --- | --- |
| Initialize workspace | `ace-prompt-prep setup` |
| Process prompt | `ace-prompt-prep process` |
| Process and write output | `ace-prompt-prep process --output /tmp/prompt.md` |
| Enhance prompt | `ace-prompt-prep process --enhance` |
| Enable context | `ace-prompt-prep process --bundle` |
| Disable context | `ace-prompt-prep process --no-bundle` |
| Task workspace | `ace-prompt-prep setup --task 121` |
| Show version | `ace-prompt-prep --version` |

## What to try next

- Add custom templates under your templates source.
- Tune enhancement settings in `.ace/prompt-prep/config.yml`.
- Turn on task detection in config for automatic task prompt routing.
