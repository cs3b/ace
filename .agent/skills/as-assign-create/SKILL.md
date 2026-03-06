---
name: as-assign-create
description: Create a new assignment from job.yaml
# bundle: wfi://assign/create
# agent: general-purpose
user-invocable: true
allowed-tools:
  - Bash(ace-assign:*)
  - Bash(ace-bundle:*)
  - Read
  - Write
  - AskUserQuestion
argument-hint: "[path/to/job.yaml]"
last_modified: 2026-02-11
source: ace-assign
---

read and run `ace-bundle wfi://assign/create`
