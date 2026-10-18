---
doc-type: user
title: ace-assign Usage Guide
purpose: Command reference for local assignment plans, hierarchy, and fork execution.
ace-docs:
  last-updated: 2026-10-17
  last-checked: 2026-10-17
---

# ace-assign Usage Guide

> **State owner:** `.ace-local/assign/` -- assignment plans and step state owned
> by `ace-assign`. There is no second queue; steps are never copied into the
> private overseer list or coworker configuration. See
> [docs/lab-flow.md](../../docs/lab-flow.md).

## Testing contract

- `bin/ace-test ace-assign` - default deterministic package loop (`test/fast`)
- `bin/ace-test ace-assign feat` - deterministic feature/contract coverage
- `bin/ace-test ace-assign all` - full package deterministic coverage
- `bin/ace-test-e2e ace-assign` - scenario workflows under `test/e2e`

## Core lifecycle

An assignment is a numbered plan stored under `.ace-local/assign/`. Step state
moves `pending` → `in_progress` → `done` or `failed`. Commands without
`--assignment` act on the selected (active) assignment.

```bash
ace-assign create --task abc123 --preset work-on-task
ace-assign list
ace-assign status
ace-assign step
ace-assign start
ace-assign finish --message report.md
```

`finish` accepts report content as a string, a file path, or stdin. Without
report content it fails instead of completing the step silently.

## Hierarchical steps

Steps are numbered `010`, `020`, `100`, and children use dots:
`010.01`, `010.01.01`.

- A parent completes only when all of its children are done.
- Traversal prioritizes pending children before siblings.
- Inserting siblings in an occupied range renumbers the following steps.
- `--child` inserts a step as a child of `--after`.

## Commands

### `ace-assign create`

Create an assignment from a preset or a YAML definition.

| Option | Purpose |
|--------|---------|
| `--yaml` | Path to a job YAML file |
| `--task`, `-t` | Task reference(s); repeatable and comma-separated |
| `--preset`, `-p` | Assignment preset name (task mode only) |
| `--quiet`, `--debug` | Output control |

```bash
ace-assign create --yaml job.yaml
ace-assign create --task t.xyz
ace-assign create --task t.100,t.101 --preset work-on-task
```

When `--task` refs expand through the `work-on-task` preset, terminal tasks are
filtered before the assignment's own step expansion:

- Terminal refs (`done`, `skipped`, `cancelled`) are skipped before queue expansion.
- Mixed sets continue with remaining non-terminal refs and report skipped terminal refs.
- All requested tasks are already terminal (done/skipped/cancelled): <refs>

The last case creates no assignment and returns that message instead.

`ace-assign` is role- and folder-name-agnostic: it delegates any non-terminal
task the caller names. The caller decides which tasks are appropriate; the
assignment tool does not classify management tasks or inspect `.gitignore`.

### `ace-assign status`

Show plan progress.

| Option | Purpose |
|--------|---------|
| `--mode` | Text mode: `compact` (default), `progress`, `full` |
| `--format` | `table` (default) or `json` |
| `--flat` | Flat list (full mode only) |
| `--assignment` | Show one assignment ID |
| `--all`, `-a` | Include completed assignments |

### `ace-assign step [STEP]`

Show instructions for the active, next, or explicit step.

### `ace-assign start [STEP]`

Start the next workable pending step, or an explicit step number.

### `ace-assign finish [STEP] --message VALUE`

Complete the active step with report content.

```bash
ace-assign finish --message "done"
ace-assign finish --message report.md
cat report.md | ace-assign finish
```

### `ace-assign fail --message TEXT`

Mark the current step failed. The error message is required.

### `ace-assign add`

Add step(s) to the plan dynamically.

| Option | Purpose |
|--------|---------|
| `--yaml` | YAML file with a top-level `steps:` array |
| `--step` | Preset step name(s), comma-separated |
| `--task` | Task reference expanded from a preset child template |
| `--preset` | Preset name (required only for `--step`/`--task`) |
| `--after`, `-a` | Insert after this step number (e.g. `010`) |
| `--child`, `-c` | Insert as a child of `--after` |
| `--assignment` | Target a specific assignment |

```bash
ace-assign add --task t.xyz
ace-assign add --step update-docs --after 020
ace-assign add --step review-pr --after 100 --child
ace-assign add --yaml add-task.yml --after 010 --child
```

### `ace-assign retry STEP_REF`

Retry a failed step by creating a new linked step.

```bash
ace-assign retry 040
```

### `ace-assign fork-run`

Prepare fork execution for an entire subtree.

| Option | Purpose |
|--------|---------|
| `--root` | Fork subtree root step number (e.g. `010.01`) |
| `--provider` | LLM provider:model override |
| `--cli-args` | Extra CLI args for the provider process |
| `--timeout` | Execution timeout in seconds |
| `--launch-mode` | `auto`, `headless`, `tmux`, or `herdr` |
| `--callback` | Capture the origin pane and receive a final callback there |

```bash
ace-assign fork-run --root 010.01
ace-assign fork-run --root 010.01 --provider codex:gpt-5 --timeout 900
```

### `ace-assign list`

List assignments. `--all` includes completed ones, `--task` filters by task
ref, `--tree` shows the hierarchy, `--format json` exports.

### `ace-assign select [ID]`

Select the active assignment. `--clear` reverts to `.latest`.

## Workflow patterns

### Scoped subtree execution

If several assignments are open, scope every command to the exact assignment
(and optionally a subtree):

```bash
ace-assign status --assignment abc123
ace-assign finish --message report.md --assignment abc123
```

### Recovery from failure

Keep the failed step intact; add a retry or a fix step, then continue. Do not
delete steps to hide a failure.

### Multi-assignment management

Use `ace-assign list --all` and `ace-assign select` to switch between open
plans. Each plan keeps its own history.

## Exit codes

| Code | Meaning |
|------|---------|
| 0 | Success |
| 1 | General error (invalid step reference, rejected report, unhandled error) |
| 2 | Assignment error (no active/known assignment) |
| 3 | Configuration not found |
| 4 | Step not found |
| 5 | Lifecycle conflict or busy maintenance exclusion (conflicting identity or busy/expired maintenance; the operation is refused, not retried in a loop) |
| 130 | Interrupted (SIGINT) |

## Planned waves

> **Planned (L3):** `ace-coworker` starts from `.ace-local/coworker/`, drives
> the assignment, records results, and reports through HITL -- not available
> yet.
>
> **Planned (L5.5):** role rules, independent review rounds, and forge
> delivery workflow -- not available yet.

The old protected/attempt-evidence and installation paths are removed from the
local flow. No journal, admission service, or second queue is required to
create, read, or drive an assignment.
