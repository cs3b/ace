---
name: as-review-verify-feedback
description: Verify feedback items through multi-dimensional claim analysis
user-invocable: true
allowed-tools:
- Bash(ace-review:*)
- Bash(ace-bundle:*)
- Read
- Grep
- Glob
argument-hint: "[--session <path>]"
last_modified: 2026-02-04
source: ace-review
skill:
  kind: workflow
  execution:
    workflow: wfi://review/verify-feedback
---

read and run `ace-bundle wfi://review/verify-feedback`
