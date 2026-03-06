---
name: as-review-pr
description: Review PR and Plan Feedback
# context: no-fork
# agent: general-purpose
user-invocable: true
allowed-tools:
  - Bash(ace-review:*)
  - Bash(ace-bundle:*)
  - Read
  - TodoWrite
argument-hint: "[#]"
last_modified: 2026-01-10
source: ace-review
---

read and run `ace-bundle wfi://review/pr`

**CRITICAL REMINDER**: After implementing ANY fix from feedback:
1. Run `ace-review-feedback resolve {id} --resolution "Fixed: <description>"`
2. Never leave fixed items in "pending" status
