---
name: as-overseer
description: Orchestrate task worktrees with ace-overseer (work-on, status, prune)
user-invocable: true
allowed-tools:
  - Bash(ace-overseer:*)
  - Bash(ace-bundle:*)
  - Read
argument-hint: "[task-ref] [--preset name]"
last_modified: 2026-02-17
source: ace-overseer
---

## Work On Task

Run:

```bash
ace-overseer work-on --task $ARGUMENTS
```

Examples:

```bash
ace-overseer work-on --task 230
ace-overseer work-on --task 230 --preset fix-bug
```

## Related Commands

Use directly when needed:

```bash
ace-overseer status
ace-overseer status --format json
ace-overseer prune --dry-run
ace-overseer prune --yes
```
