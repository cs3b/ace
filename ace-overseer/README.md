---
doc-type: user
title: ace-overseer
purpose: Documentation for ace-overseer/README.md
ace-docs:
  last-updated: 2026-02-19
  last-checked: 2026-03-21
---

# ace-overseer

`ace-overseer` is the project control plane for multi-task execution across git worktrees.

It composes existing ACE tools through their public Ruby SDKs:
- `ace-git-worktree` (worktree lifecycle)
- `ace-tmux` (window/session management)
- `ace-assign` (assignment creation and progress)
- `ace-taskflow` (task metadata and release status)
- `ace-git` (repo status)

## Quick Start

```bash
# Start working on task 230 in one command
ace-overseer work-on --task 230

# Monitor all active task worktrees
ace-overseer status

# Machine-readable status
ace-overseer status --format json

# Safe cleanup preview
ace-overseer prune --dry-run
```

`work-on` provisions/reuses a task worktree, opens a tmux window, and creates an assignment in that worktree.

## Commands

### `ace-overseer work-on --task <ref> [--preset <name>]`

Creates or reuses a task worktree, opens a tmux window, and prepares an assignment.

Examples:

```bash
ace-overseer work-on --task 230
ace-overseer work-on --task 230 --preset fix-bug
```

### `ace-overseer status [--format table|json]`

Displays a dashboard of active task worktrees with assignment and git state.

### `ace-overseer prune [--dry-run] [--yes]`

Prunes only safe candidates:
- assignment completed
- task marked done
- git clean

`--dry-run` shows candidates without removal.
`--yes` skips confirmation.

## Configuration

Defaults are in `ace-overseer/.ace-defaults/overseer/config.yml`:

```yaml
tmux_session_name: "ace"
window_preset: "cc"
default_assign_preset: "work-on-task"
window_name_format: "t{task_id}"
```

## Development

```bash
# Run package tests
ace-test ace-overseer

# Version
ace-overseer version
```
