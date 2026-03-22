---
doc-type: user
title: ace-overseer Getting Started
purpose: Tutorial for launching and managing task worktrees with ace-overseer.
ace-docs:
  last-updated: 2026-03-22
  last-checked: 2026-03-22
---

# Getting Started with ace-overseer

## Prerequisites

- `tmux` installed and available on your PATH
- ACE toolkit installed in your repository
- A task reference (for example `8q4.t.umu.1`) ready to execute

## Installation

Install as part of the ACE mono-repo toolchain: `mise exec -- ace-overseer --help`.

If the command resolves, your environment is ready.

## Start Work on a Task

Launch a focused task workspace: `mise exec -- ace-overseer work-on --task 8q4.t.umu.1`.

This flow provisions or reuses a task worktree, opens a tmux window, and prepares assignment context.

## Monitor Active Work

Inspect the task dashboard: `mise exec -- ace-overseer status`.

Need machine-readable output? Use `mise exec -- ace-overseer status --format json`.

## Prune Completed Worktrees

Preview prune candidates first: `mise exec -- ace-overseer prune --dry-run`.

When safe to remove, confirm cleanup: `mise exec -- ace-overseer prune --yes`.

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
