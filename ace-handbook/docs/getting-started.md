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
- `ace-nav` and `ace-bundle` available through `mise exec --`

## Installation

Install the gem when using ACE components outside the monorepo:

```bash
gem install ace-handbook

```

Inside this repository, use commands through `mise`:

```bash
mise exec -- ace-nav list 'wfi://handbook/*'

```

## Creating your first guide

Discover the guide-management workflow path:

```bash
mise exec -- ace-nav resolve wfi://handbook/manage-guides

```

Load and follow the full workflow:

```bash
mise exec -- ace-bundle wfi://handbook/manage-guides

```

## Managing workflow instructions

Create or update `.wf.md` files:

```bash
mise exec -- ace-bundle wfi://handbook/manage-workflows

```

Run the review workflow before finalizing changes:

```bash
mise exec -- ace-bundle wfi://handbook/review-workflows

```

## Creating agent definitions

For package-managed agent definitions (`.ag.md`), load:

```bash
mise exec -- ace-bundle wfi://handbook/manage-agents

```

## Reviewing guides for consistency

Run the guide review workflow to enforce standards:

```bash
mise exec -- ace-bundle wfi://handbook/review-guides

```

## Common commands

| Command | Purpose |
| --- | --- |
| `mise exec -- ace-nav list 'wfi://handbook/*'` | Discover handbook workflows |
| `mise exec -- ace-nav resolve wfi://handbook/manage-guides` | Resolve workflow path |
| `mise exec -- ace-bundle wfi://handbook/manage-guides` | Create/update guides |
| `mise exec -- ace-bundle wfi://handbook/manage-workflows` | Create/update workflow instructions |
| `mise exec -- ace-bundle wfi://handbook/manage-agents` | Create/update agent definitions |
| `mise exec -- ace-bundle wfi://handbook/review-guides` | Review guide quality |
| `mise exec -- ace-bundle wfi://handbook/review-workflows` | Review workflow quality |
| `mise exec -- ace-bundle wfi://handbook/update-docs` | Refresh package docs |

## Next steps

- Continue with [Usage Reference](usage.md) for detailed command patterns.
- Use [Handbook Reference](handbook.md) for skill/workflow catalog and source paths.
- Keep handbook standards aligned during updates with `wfi://handbook/update-docs`.
