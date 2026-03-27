---
doc-type: user
title: ace-assign Usage Guide
purpose: Complete command reference for ace-assign queue orchestration, hierarchy, and fork execution.
ace-docs:
  last-updated: 2026-03-26
  last-checked: 2026-03-26
---

# ace-assign Usage Guide

`ace-assign` manages assignment queues with explicit step states and optional hierarchy.

## Command Integrity

When documenting or automating `ace-*` flows, prefer direct commands and explicit report files.

Recommended:


```bash
ace-assign finish --message report.md
```

## Core Lifecycle


```bash
ace-assign create --yaml job.yaml
ace-assign status
ace-assign finish --message step-010.md
ace-assign status
```

Use scoped targeting when needed:


```bash
ace-assign status --assignment abc123@010.01
ace-assign finish --message done.md --assignment abc123@010.01
```

## Hierarchical Steps

### Numbering

- Top-level: `010`, `020`, `030`
- Child: `010.01`, `010.02`
- Grandchild: `010.01.01`

### Rules

- Parents auto-complete when all descendants are done.
- Queue traversal works deepest actionable step first.
- Inserted siblings can renumber later siblings (and descendants).

Create child/sibling steps:


```bash
ace-assign add --step setup-db --after 010 --child
ace-assign add --step hotfix --after 010
ace-assign add --yaml .ace-local/assign/jobs/add-task.yml --after 010 --child
```

## Commands

### `ace-assign create`

Create a new assignment from YAML or from task refs expanded through an assignment preset.

Options:

- `--yaml FILE`
- `--task, -t <taskref[,taskref...]>` (repeatable)
- `--preset, -p NAME`
- `--quiet, -q`
- `--debug, -d`

Exactly one mode is required: `--yaml` or `--task`.

### `ace-assign status`

Show queue status for active or explicitly targeted assignment.

Options:

- `--flat, -f`
- `--format table|json`
- `--assignment <id>`
- `--all, -a`
- `--quiet, -q`
- `--debug, -d`

### `ace-assign start [STEP]`

Start next workable pending step, or an explicit pending step in the active assignment.

Options:

- `--assignment <id>`
- `--quiet, -q`
- `--debug, -d`

### `ace-assign finish [STEP] --message VALUE`

Complete current in-progress step (or explicit step in active assignment) with report content.

`--message` accepts:

- Inline text
- File path

Options:

- `--message, -m` (required)
- `--assignment <id>`
- `--quiet, -q`
- `--debug, -d`

### `ace-assign fail --message TEXT`

Mark current step as failed.

Options:

- `--message, -m` (required)
- `--assignment <id>`
- `--quiet, -q`
- `--debug, -d`

### `ace-assign add`

Insert new step(s) dynamically.

Options:

- `--yaml FILE`
- `--step NAME[,NAME...]`
- `--task TASKREF`
- `--preset NAME`
- `--after, -a NUMBER`
- `--child, -c`
- `--assignment <id>`
- `--quiet, -q`
- `--debug, -d`

Exactly one mode is required: `--yaml`, `--step`, or `--task`.

### `ace-assign retry STEP_REF`

Create a linked retry step for a failed step.

Options:

- `--assignment <id>`
- `--quiet, -q`
- `--debug, -d`

### `ace-assign fork-run`

Execute a fork-enabled subtree in an isolated process.

Options:

- `--root <step-number>`
- `--assignment <id>`
- `--provider <provider:model>`
- `--cli-args <args>`
- `--timeout <seconds>`
- `--quiet, -q`
- `--debug, -d`

### `ace-assign list`

List assignments.

Options:

- `--all, -a`
- `--task, -t <taskref>`
- `--tree`
- `--format table|json`
- `--quiet, -q`
- `--debug, -d`

### `ace-assign select [ID]`

Select active assignment or clear selection.

Options:

- `--clear`
- `--quiet, -q`
- `--debug, -d`

## Workflow Patterns

### `work-on-task` Input Filtering (Prepare/Create Workflows)

When using preset-backed assignment creation (`ace-assign create --task ...`, `/as-assign-prepare`, or `/as-assign-create`):

- Requested refs are resolved first (single, comma list, range, pattern).
- Terminal refs (`done`, `skipped`, `cancelled`) are skipped before queue expansion.
- Mixed sets continue with remaining non-terminal refs and report skipped terminal refs.
- If all requested refs are terminal, assignment creation stops with:
  - `All requested tasks are already terminal (done/skipped/cancelled): <refs>`
  - `No assignment created.`

### Scoped Subtree Execution


```bash
ace-assign status --assignment abc123@010.01
ace-assign fork-run --assignment abc123@010.01
```

### Recovery from Failure


```bash
ace-assign fail --message "Lint failed in docs"
ace-assign retry 040 --assignment abc123
```

### Multi-assignment Management


```bash
ace-assign list --all
ace-assign select abc123
ace-assign select --clear
```

## Exit Codes

| Code | Meaning |
|------|---------|
| 0 | Success |
| 1 | General error |
| 2 | Assignment error |
| 3 | Configuration not found |
| 4 | Step not found |
| 130 | Interrupted (SIGINT) |

See [exit-codes.md](exit-codes.md) for complete descriptions.
