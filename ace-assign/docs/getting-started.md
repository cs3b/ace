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
ace-assign create job.yaml
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
ace-assign add fix-links --instructions "Fix broken docs links"
ace-assign add verify-links --after 020 --child -i "Check all markdown links"
```

Use `--child` to insert nested phases under a parent step.

## 4) Work with hierarchical phases

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
| `ace-assign create job.yaml` | Create assignment from YAML |
| `ace-assign status` | Show current queue |
| `ace-assign start` | Start next workable step |
| `ace-assign finish --message done.md` | Complete in-progress step |
| `ace-assign fail --message "error"` | Mark current step failed |
| `ace-assign add NAME -i "..."` | Insert new step dynamically |
| `ace-assign retry 040` | Retry failed step as linked work |
| `ace-assign fork-run --root 010.01` | Execute a subtree in forked context |

## Next steps

- [Usage Guide](usage.md) for full command reference
- [Handbook Reference](handbook.md) for skills/workflows inventory
- [Fork Context Guide](../handbook/guides/fork-context.g.md) for delegation and recovery patterns
- Runtime help: `ace-assign --help`
