---
name: as-review-package
description: Review Package - Comprehensive code, docs, UX/DX review with recommendations
# bundle: wfi://review/package
# context: no-fork
# agent: Explore
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
argument-hint: [package-name]
last_modified: 2026-01-10
source: ace-review
integration:
  targets:
    - claude
    - codex
    - gemini
    - opencode
    - pi
  providers: {}
skill:
  kind: workflow
  execution:
    workflow: wfi://review/package
---

Load and run `mise exec -- ace-bundle wfi://review/package` in the current project, then follow the loaded workflow as the source of truth and execute it end-to-end instead of only summarizing it.
