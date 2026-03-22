---
name: as-task-review-questions
description: Review and answer clarifying questions about task or implementation
# bundle: wfi://task/review-questions
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
skill:
  kind: workflow
  execution:
    workflow: wfi://task/review-questions

---

Load and run `ace-bundle wfi://task/review-questions` in the current project, then follow the loaded workflow as the source of truth and execute it end-to-end instead of only summarizing it.

