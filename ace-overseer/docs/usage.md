---
doc-type: user
title: ace-overseer Usage
purpose: CLI reference for local overseer worktrees, assignments, and cleanup.
ace-docs:
  last-updated: 2026-10-17
  last-checked: 2026-10-17
---

# Usage

> **State owner:** `.ace-local/overseer/tasks/` (private, untracked `_overseer`
> list via `ace-task --in _overseer`) and `.ace-wt/` (one worktree per project
> task). Assignment plans live in `.ace-local/assign/` and are not copied here.
> See [docs/lab-flow.md](../../docs/lab-flow.md).

## Command Surface

Local work uses three commands:

- `ace-overseer work-on` - prepare a worktree, assignment, and terminal.
- `ace-overseer status` - show active task worktrees and assignment progress.
- `ace-overseer prune` - remove completed task worktrees safely.

`--project`/`--agent` protected execution is removed in L1 and is not a normal
path. tmux and Herdr are transports, never state owners.

## `ace-overseer work-on`

Create or reuse local worktrees and prepare one assignment.

| Option | Purpose |
|--------|---------|
| `--task`, `-t` | Task ref(s); repeatable and comma-separated |
| `--preset`, `-p` | Assignment preset name (default `work-on-task`) |
| `--runtime` | Terminal backend: `auto`, `tmux` or `herdr` |
| `--quiet`, `-q` | Suppress non-essential output |
| `--debug`, `-d` | Show debug output |

```bash
ace-overseer work-on --task 8q4
ace-overseer work-on --task t.123,t.124 --preset work-on-task --runtime herdr
```

Work-on is idempotent: rerunning with the same task refs reuses the existing
worktree and assignment instead of creating duplicates. Draft tasks are
blocked until reviewed.

> **Planned (L4):** planner prepares the worktree and the entire assignment
> sequence -- not available yet.

## `ace-overseer status`

Show status for active task worktrees.

```bash
ace-overseer status
ace-overseer status --format json
ace-overseer status --watch
```

| Option | Purpose |
|--------|---------|
| `--format` | `table` (default) or `json` |
| `--watch`, `-w` | Auto-refresh the dashboard |
| `--runtime` | Terminal backend used for pane checks |
| `--quiet`, `-q` | Suppress non-essential output |
| `--debug`, `-d` | Show debug output |

Status reads local assignments and git state. Missing or unreadable evidence is
shown as unknown rather than as success.

> **Planned (L7):** configured status aggregation and pi continuation -- not
> available yet.

## `ace-overseer prune`

Remove completed task worktrees. A candidate is removed only when the
assignment is complete, the task is marked done, and the git working tree is
clean. `--force`/`--yes` never override those blocks.

```bash
ace-overseer prune --dry-run
ace-overseer prune --yes
ace-overseer prune 8q4 --dry-run
ace-overseer prune --assignment abc123
```

| Option | Purpose |
|--------|---------|
| `TARGETS` | Task refs or folder names to prune |
| `--assignment`, `-a` | Prune a specific assignment by ID |
| `--dry-run` | Show candidates only; no cleanup side effects |
| `--yes`, `-y` | Skip the confirmation prompt |
| `--force`, `-f` | Skip confirmation for already-safe candidates; never bypasses safety blocks |
| `--preservation FILE` | YAML manifest declaring verified cross-repository destinations |
| `--quiet`, `-q` | Suppress progress output |
| `--debug`, `-d` | Show debug output |

Dry-run exits 0 even when it lists blocked candidates. Apply exits non-zero
when any selected candidate is blocked or removal fails; independent safe
candidates still complete. Unmatched explicit targets are errors.

> **Planned (L6):** private queue and worktree handoff between roles -- not
> available yet.

## Terminal runtime configuration

Work-on opens the task terminal and prune closes its window through the
runtime-neutral [ace-runtime](../ace-runtime) contract. Select the backend in
`.ace/overseer/config.yml`:

```yaml
# tmux | herdr | auto (default): auto detects tmux first, then herdr.
# ACE_RUNTIME wins over this key; nothing detected fails explicitly.
runtime: auto
window_presets:
  "work-on-task": "work-on-task"
```

## Example flows

Start task work and check the dashboard:

```bash
ace-overseer work-on --task t.123
ace-overseer status --format json
```

Preview and prune finished work:

```bash
ace-task update t.123 --set status=done
ace-overseer prune --dry-run
ace-overseer prune --yes
ace-overseer prune --dry-run
```
