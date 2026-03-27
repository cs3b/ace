---
doc-type: user
title: Getting Started with ace-assign
purpose: Tutorial for creating, running, and adapting assignment queues with ace-assign.
ace-docs:
  last-updated: 2026-03-22
  last-checked: 2026-03-22
---

# Getting Started with ace-assign

Use `ace-assign` to run multi-step work as a durable queue instead of ad-hoc notes.

## Prerequisites

- Ruby 3.2+
- `ace-assign` installed
- A writable project directory

## Installation


```bash
gem install ace-assign
```

## 1) Create your first assignment

Create `job.yaml`:


```yaml
assignment:
  name: docs-update
  description: Update package documentation

steps:
  - name: onboard
    instructions: |
      Load context with `ace-bundle project-base`.

  - name: implement
    instructions: |
      Apply documentation updates.

  - name: verify
    instructions: |
      Run lint and tests.
```

Create the assignment:


```bash
ace-assign create --yaml job.yaml
```

Or create directly from task refs with the default `work-on-task` preset:

```bash
ace-assign create --task t.xyz
ace-assign create --task t.100,t.101 --preset work-on-task
```

## 2) Check status and execute work


```bash
ace-assign status
ace-assign finish --message onboard.md
ace-assign status
```

Use `--message <file>` to keep reports explicit and reusable.

## 3) Add work dynamically


```bash
ace-assign add --task t.xyz
ace-assign add --step update-docs --after 020
ace-assign add --step review-pr --after 100 --child
ace-assign add --yaml .ace-local/assign/jobs/add-task-t.xyz.yml --after 010 --child
```

Use `--child` to insert nested steps under a parent step.
Use `--yaml` to insert multiple steps (including subtree expansions via `sub_steps`) from YAML.

## 4) Work with hierarchical steps

- Parent steps complete when all children are done.
- Queue traversal prioritizes pending children before siblings.
- Renumbering cascades when inserting siblings in occupied ranges.

Use status views:


```bash
ace-assign status
ace-assign status --flat
```

## 5) Use scoped assignment targeting

If you manage multiple assignments (or a subtree), always scope commands:


```bash
ace-assign status --assignment abc123@010.01
ace-assign finish --message report.md --assignment abc123@010.01
```

## Common Commands

| Command | Purpose |
|---------|---------|
| `ace-assign create --yaml job.yaml` | Create assignment from YAML |
| `ace-assign create --task t.xyz` | Create assignment from task refs |
| `ace-assign status` | Show current queue |
| `ace-assign start` | Start next workable step |
| `ace-assign finish --message done.md` | Complete in-progress step |
| `ace-assign fail --message "error"` | Mark current step failed |
| `ace-assign add --step NAME` | Insert preset step dynamically |
| `ace-assign retry 040` | Retry failed step as linked work |
| `ace-assign fork-run --root 010.01` | Execute a subtree in forked context |

## Next steps

- [Usage Guide](usage.md) for full command reference
- [Handbook Reference](handbook.md) for skills/workflows inventory
- [Fork Context Guide](../handbook/guides/fork-context.g.md) for delegation and recovery patterns
- Runtime help: `ace-assign --help`
