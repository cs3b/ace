---
name: as-assign-prepare
description: Legacy/internal helper to prepare job.yaml from preset or informal instructions
# bundle: wfi://assign/prepare
# agent: general-purpose
user-invocable: false
allowed-tools:
  - Bash(ls:*)
  - Bash(cat:*)
  - Bash(ace-bundle:*)
  - Read
  - Write
  - AskUserQuestion
argument-hint: "[preset-name] [--taskref value] [--output path]"
last_modified: 2026-02-11
source: ace-assign
---

read and run `ace-bundle wfi://assign/prepare`
