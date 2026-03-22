---
name: as-handbook-init-project
description: Initialize Project Structure
# bundle: wfi://handbook/init-project
# context: no-fork
# agent: general-purpose
user-invocable: true
allowed-tools:
  - Bash(ace-handbook:*)
  - Bash(ace-bundle:*)
  - Bash(ace-git-commit:*)
  - Read
  - Write
  - Edit
  - Grep
argument-hint: [project-path]
last_modified: 2026-01-10
source: ace-handbook
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
    workflow: wfi://handbook/init-project
---

Load and run `ace-bundle wfi://handbook/init-project` in the current project, then follow the loaded workflow as the source of truth and execute it end-to-end instead of only summarizing it.

