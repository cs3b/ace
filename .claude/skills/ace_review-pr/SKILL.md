---
name: ace:review-pr
description: Review PR and Plan Feedback
# context: no-fork
# agent: general-purpose
user-invocable: true
allowed-tools:
  - Bash(ace-review:*)
  - Bash(ace-bundle:*)
  - Read
  - TodoWrite
  - AskUserQuestion
argument-hint: [#]
last_modified: 2026-01-10
source: ace-review
---

read and run `ace-bundle wfi://review-pr`
