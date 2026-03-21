---
doc-type: user
title: Getting Started with ace-bundle
purpose: Documentation for ace-bundle/docs/getting-started.md
ace-docs:
  last-updated: 2026-03-21
  last-checked: 2026-03-21
---

# Getting Started with ace-bundle

Use `ace-bundle` when you want repeatable project context for AI agents and developers.

## Prerequisites

- Ruby installed
- `ace-bundle` installed:

Run:


```bash
gem install ace-bundle
```

## 1) Run your first bundle

Run:


```bash
ace-bundle project
```

This loads the `project` preset and returns context assembled from configured files, commands, and sections.

## 2) Read the output

`ace-bundle` may print directly to stdout or save a cache artifact. When cached, you will see a path like:

- `.ace-local/bundle/project.md`

Read that file directly to inspect the full bundled context.

## 3) Explore available presets

Run:


```bash
ace-bundle --list
ace-bundle project-base
```

Use `project-base` when you need lightweight onboarding context, and `project` when you need broader repository state.

## 4) Create a custom preset

Create `.ace/bundle/presets/my-context.md`:

Example preset:


```markdown
---
description: My focused context
bundle:
  files:
    - README.md
    - docs/**/*.md
---

# Extra Notes

Add team-specific guidance here.
```

Then run:

Run:


```bash
ace-bundle my-context
```

## 5) Use protocol resources

Run:


```bash
ace-bundle wfi://task/plan
ace-bundle guide://workflow-context-embedding
```

Protocols let you load canonical ACE workflows and guides without hardcoding file paths.

## Common Commands

| Command | What it does |
|---------|-------------|
| `ace-bundle project` | Load full project context |
| `ace-bundle project-base` | Lightweight onboarding context |
| `ace-bundle --list` | List available presets |
| `ace-bundle wfi://task/plan` | Load workflow via protocol |
| `ace-bundle -p base -p custom` | Merge multiple presets |
| `ace-bundle project --inspect-config` | Show resolved configuration |

## What to try next

- [Usage Guide](usage.md) — full command reference with all options
- [Configuration Reference](configuration.md) — preset format, sections, parameters
- [Handbook Reference](handbook.md) — skills, workflows, built-in presets
- Runtime help: `ace-bundle --help`
