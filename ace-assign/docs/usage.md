---
doc-type: user
title: ace-assign Usage Guide
purpose: Complete command reference for ace-assign queue orchestration, hierarchy,
  and fork execution.
ace-docs:
  last-updated: '2026-04-23'
  last-checked: '2026-04-23'
---

# ace-assign Usage Guide

`ace-assign` manages assignment queues with explicit step states and optional hierarchy.

## Command Integrity

When documenting or automating `ace-*` flows, prefer direct commands and explicit report files.

Recommended:


```bash
ace-assign finish --message report.md
```

## Testing Contract

Use package-scoped test commands with explicit layers:

```bash
ace-test ace-assign
ace-test ace-assign feat
ace-test ace-assign all
ace-test-e2e ace-assign
```

For assignment verification, `verify-test-suite` is the standard gate:

```bash
ace-test <package> all --profile 6
ace-test-suite --target all
```

## Core Lifecycle


```bash
ace-assign create --yaml job.yaml
ace-assign status
ace-assign start
ace-assign step
ace-assign finish --message step-010.md
ace-assign status
```

Use scoped targeting when needed:


```bash
ace-assign status --assignment abc123@010.01
ace-assign start --assignment abc123@010.01
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
ace-assign add --step update-docs --after 020
ace-assign add --step review-pr --after 100 --child
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
- `--mode compact|progress|full`
- `--format table|json`
- `--assignment <id>`
- `--all, -a`
- `--quiet, -q`
- `--debug, -d`

Text modes:

- `compact` (default) prints a short summary, hidden-step stats, and up to 5 upcoming step lines
- `progress` prints a single summary line
- `full` prints the full tree/table without step instructions
- JSON emits `active_steps` for all active steps in scope and `next_step` only when no step is active in that scope

HITL stall behavior:

- Canonical contract lives in `wfi://hitl` (`ace-hitl` package workflow).
- If a step is failed with canonical message format `HITL: <id> <path>`, `ace-assign status` prints operator guidance with the matching `ace-hitl show <id>` command and available path hint.
- Recommended resume flow:
  - `ace-hitl show <id>`
  - requester path (default): `ace-hitl wait <id>`
  - fallback path (when waiter inactive): `ace-hitl update <id> --answer "<decision>" --resume`
  - `ace-assign retry <failed-step> --assignment <assignment-id>`
- Completion-attention flow:
  - When assignment work is complete but explicit user action is needed, create an approval HITL event (`kind=approval`) and include the resume instruction for `/as-assign-drive <assignment-id>`.

### `ace-assign step [STEP]`

Show instructions for the deepest active step in scope, the next workable pending step when nothing is active, or an explicit step number.

Options:

- `--assignment <id>`
- `--quiet, -q`
- `--debug, -d`

### `ace-assign start [STEP]`

Mark the next workable pending step active, or mark an explicit pending step active in the targeted assignment or subtree.

Options:

- `--assignment <id>`
- `--quiet, -q`
- `--debug, -d`

### `ace-assign finish [STEP] --message VALUE`

Complete the current active step (or explicit active step in the active assignment) with report content.
Use positional `STEP` only for the active assignment. When targeting another
assignment or a scoped subtree, pass `--assignment <id>` or
`--assignment <id@step>` without a positional `STEP`; the command finishes the
deepest active step in that target.

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
- `--launch-mode auto|headless|tmux`
- `--quiet, -q`
- `--debug, -d`

Launch modes:

- `auto` (default): use tmux when the current process is already inside tmux or `ACE_TMUX_SESSION` is set; otherwise use the headless subprocess path
- `headless`: force the existing provider subprocess path and never create tmux panes
- `tmux`: require tmux context, create or reuse `<current-window>-fs`, start a real interactive agent in a pane there via `ace-llm --interactive`, and send the scoped `/as-assign-drive <assignment>@<root>` handoff automatically. The fork window name uses the shared `ace-tmux` safe-name policy, so punctuation in the base window is replaced with `-`.

Provider resolution precedence for fork execution:

1. CLI `--provider`
2. Step frontmatter `fork.provider`
3. Config `execution.provider`
4. Built-in default provider

Step-level example:

```yaml
---
name: research
status: pending
context: fork
fork:
  provider: "claude:sonnet@yolo"
---
```

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