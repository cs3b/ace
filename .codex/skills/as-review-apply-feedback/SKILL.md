---
name: as-review-apply-feedback
description: Apply verified feedback items from code review
user-invocable: true
allowed-tools:
- Bash(ace-review:*)
- Bash(ace-bundle:*)
- Read
- Write
- Edit
- Grep
- Glob
argument-hint: "[--session <path>] [--priority <level>]"
last_modified: 2026-02-03
source: ace-review
skill:
  kind: workflow
  execution:
    workflow: wfi://review/apply-feedback
---

read and run `ace-bundle wfi://review/apply-feedback`
