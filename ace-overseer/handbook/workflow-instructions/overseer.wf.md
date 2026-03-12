---
name: overseer
description: Orchestrate task worktrees with ace-overseer
allowed-tools: Bash, Read
argument-hint: "[task-ref] [--preset name]"
doc-type: workflow
purpose: overseer workflow
---

# Overseer Workflow

## Instructions

1. For work-on flows, run `ace-overseer work-on --task $ARGUMENTS`.
2. Use `ace-overseer status` to inspect active worktrees.
3. Use `ace-overseer prune --dry-run` before destructive cleanup, then `ace-overseer prune --yes` when confirmed.
