---
name: ace-docs-update-roadmap
description: Update project roadmap with current progress and upcoming milestones
# context: no-fork
# agent: general-purpose
user-invocable: true
allowed-tools:
  - Bash(ace-task:*)
  - Bash(ace-bundle:*)
  - Read
  - Write
  - Edit
argument-hint: [release-branch]
last_modified: 2026-01-10
source: ace-task
---

read and run `ace-bundle wfi://docs/update-roadmap`
