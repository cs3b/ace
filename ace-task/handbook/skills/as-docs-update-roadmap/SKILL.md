---
name: as-docs-update-roadmap
description: Update project roadmap with current progress and upcoming milestones
# bundle: wfi://docs/update-roadmap
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
skill:
  kind: workflow
  execution:
    workflow: wfi://docs/update-roadmap

---

read and run `ace-bundle wfi://docs/update-roadmap`
