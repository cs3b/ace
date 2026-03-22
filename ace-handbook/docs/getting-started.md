---
doc-type: user
title: Ace::Handbook Getting Started
purpose: Tutorial for using ace-handbook workflows
ace-docs:
  last-updated: 2026-03-22
  last-checked: 2026-03-22
---

# Getting Started with ace-handbook

## Prerequisites

- ACE repository available locally
- `mise` installed for managed runtime/tool execution
- `ace-nav` and `ace-bundle` available on your PATH

## Installation

Install the gem when using ACE components outside the monorepo:

```bash
gem install ace-handbook

```

Inside this repository, run ACE commands directly:

```bash
ace-nav list 'wfi://handbook/*'

```

## Creating your first guide

Discover the guide-management workflow path:

```bash
ace-nav resolve wfi://handbook/manage-guides

```

Load and follow the full workflow:

```bash
ace-bundle wfi://handbook/manage-guides

```

## Managing workflow instructions

Create or update `.wf.md` files:

```bash
ace-bundle wfi://handbook/manage-workflows

```

Run the review workflow before finalizing changes:

```bash
ace-bundle wfi://handbook/review-workflows

```

## Creating agent definitions

For package-managed agent definitions (`.ag.md`), load:

```bash
ace-bundle wfi://handbook/manage-agents

```

## Reviewing guides for consistency

Run the guide review workflow to enforce standards:

```bash
ace-bundle wfi://handbook/review-guides

```

## Common commands

| Command | Purpose |
| --- | --- |
| `ace-nav list 'wfi://handbook/*'` | Discover handbook workflows |
| `ace-nav resolve wfi://handbook/manage-guides` | Resolve workflow path |
| `ace-bundle wfi://handbook/manage-guides` | Create/update guides |
| `ace-bundle wfi://handbook/manage-workflows` | Create/update workflow instructions |
| `ace-bundle wfi://handbook/manage-agents` | Create/update agent definitions |
| `ace-bundle wfi://handbook/review-guides` | Review guide quality |
| `ace-bundle wfi://handbook/review-workflows` | Review workflow quality |
| `ace-bundle wfi://handbook/update-docs` | Refresh package docs |

## Next steps

- Continue with [Usage Reference](usage.md) for detailed command patterns.
- Use [Handbook Reference](handbook.md) for skill/workflow catalog and source paths.
- Keep handbook standards aligned during updates with `wfi://handbook/update-docs`.
