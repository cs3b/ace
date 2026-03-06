---
name: as-review-verify-feedback
description: Verify feedback items through multi-dimensional claim analysis
# context: no-fork
# agent: general-purpose
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
---

read and run `ace-bundle wfi://review/verify-feedback`
