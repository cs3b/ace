---
name: as-handbook-review-guides
description: Review and validate development guides for quality and consistency
user-invocable: true
allowed-tools:
- Bash(ace-handbook:*)
- Bash(ace-bundle:*)
- Read
- Glob
- LS
- TodoWrite
argument-hint:
- guide-name
last_modified: 2026-01-10
source: ace-handbook
skill:
  kind: workflow
  execution:
    workflow: wfi://handbook/review-guides
---

read and run `ace-bundle wfi://handbook/review-guides`
