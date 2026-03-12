---
name: as-handbook-review-workflows
description: Review and validate workflow instructions for quality and consistency
user-invocable: true
allowed-tools:
- Bash(ace-handbook:*)
- Bash(ace-bundle:*)
- Read
- Glob
- LS
- TodoWrite
argument-hint:
- workflow-name
last_modified: 2026-01-10
source: ace-handbook
skill:
  kind: workflow
  execution:
    workflow: wfi://handbook/review-workflows
---

read and run `ace-bundle wfi://handbook/review-workflows`
