---
name: as-assign-prepare
description: Legacy/internal helper to prepare job.yaml from preset or informal instructions
user-invocable: false
allowed-tools:
- Bash(ace-bundle:*)
- Glob
- Read
- Write
- AskUserQuestion
argument-hint: "[preset-name] [--taskref value] [--output path]"
last_modified: 2026-02-11
source: ace-assign
skill:
  kind: workflow
  execution:
    workflow: wfi://assign/prepare
---

read and run `ace-bundle wfi://assign/prepare`
