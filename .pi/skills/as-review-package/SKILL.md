---
name: as-review-package
description: Review Package - Comprehensive code, docs, UX/DX review with recommendations
user-invocable: true
allowed-tools:
- Bash(ace-bundle:*)
- Bash(ace-git:*)
- Bash(gh:*)
- Read
- Glob
- Grep
- Write
- Edit
- TodoWrite
- Skill
argument-hint:
- package-name
last_modified: 2026-01-10
source: ace-review
skill:
  kind: workflow
  execution:
    workflow: wfi://review/package
---

read and run `ace-bundle wfi://review/package`
