---
name: as-review-pr
description: Review PR and Plan Feedback
user-invocable: true
allowed-tools:
- Bash(ace-review:*)
- Bash(ace-bundle:*)
- Read
- TodoWrite
argument-hint: "[#]"
last_modified: 2026-01-10
source: ace-review
skill:
  kind: workflow
  execution:
    workflow: wfi://review/pr
---

Load and run `mise exec -- ace-bundle wfi://review/pr` in the current project, then follow the loaded workflow as the source of truth and execute it end-to-end instead of only summarizing it.
