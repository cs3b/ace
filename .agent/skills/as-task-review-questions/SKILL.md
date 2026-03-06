---
name: as-task-review-questions
description: Review and answer clarifying questions about task or implementation
# context: no-fork
# agent: general-purpose
user-invocable: true
allowed-tools:
  - Bash(ace-task:*)
  - Bash(ace-bundle:*)
  - Read
  - Write
  - TodoWrite
argument-hint: [question-context]
last_modified: 2026-01-10
source: ace-task
---

read and run `ace-bundle wfi://task/review-questions`

read and run `ace-bundle wfi://git/commit`
