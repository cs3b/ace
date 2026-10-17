---
doc-type: user
title: ace-overseer Getting Started
purpose: Tutorial for launching and managing task worktrees with ace-overseer.
ace-docs:
  last-updated: 2026-03-22
  last-checked: 2026-03-22
---

# Getting Started with ace-overseer

> **State owner:** `.ace-tasks/_overseer/` (private, gitignored task folder
> reached via `ace-task --in _overseer`) and `.ace-wt/` (one worktree per
> project task). Assignment plans stay in `.ace-local/assign/`. See
> [docs/lab-flow.md](../../docs/lab-flow.md).

## Prerequisites

- `tmux` or Herdr installed and available on your PATH (one terminal backend)
- ACE toolkit installed in your repository
- A task reference (for example `t.123`) ready to execute

## Installation

Install as part of the ACE mono-repo toolchain: `ace-overseer --help`.

If the command resolves, your environment is ready.

## Start Work on a Task

Launch a focused task workspace: `ace-overseer work-on --task t.123`.

This flow provisions or reuses a task worktree, opens a terminal window, and prepares assignment context in `.ace-local/assign/`.

## Monitor Active Work

Inspect the task dashboard: `ace-overseer status`.

Need machine-readable output? Use `ace-overseer status --format json`.

## Prune Completed Worktrees

Preview prune candidates first: `ace-overseer prune --dry-run`.

When safe to remove, confirm cleanup: `ace-overseer prune --yes`.

## Common Commands

| Command | Purpose |
| --- | --- |
| `ace-overseer work-on --task <ref>` | Start or resume focused task workspace |
| `ace-overseer status` | Show active task worktree dashboard |
| `ace-overseer status --format json` | Export dashboard as JSON |
| `ace-overseer prune --dry-run` | Preview removable worktrees |
| `ace-overseer prune --yes` | Remove confirmed safe worktrees |

## Next steps

- Use assignment presets with `work-on --preset <name>` for repeatable workflows.
- Integrate JSON status output into scripts, dashboards, or CI checks.
- See [Usage Guide](usage.md) for full command and option reference.
