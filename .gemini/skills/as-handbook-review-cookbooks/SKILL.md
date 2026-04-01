---
name: as-handbook-review-cookbooks
description: Review and validate cookbook assets for quality and consistency
user-invocable: true
allowed-tools:
- Bash(ace-handbook:*)
- Bash(ace-bundle:*)
- Read
- Glob
- LS
- TodoWrite
argument-hint:
- cookbook-name
last_modified: 2026-04-01
source: ace-handbook
skill:
  kind: workflow
  execution:
    workflow: wfi://handbook/review-cookbooks
---

Load and run `ace-bundle wfi://handbook/review-cookbooks` in the current project, then follow the loaded workflow as the source of truth and execute it end-to-end instead of only summarizing it.
