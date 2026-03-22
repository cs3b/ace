---
name: as-git-reorganize-commits
description: Reorganize commits into logical groups
# bundle: wfi://git/reorganize-commits
# context: no-fork
# agent: general-purpose
user-invocable: true
allowed-tools:
  - Bash(ace-git:*)
  - Bash(ace-bundle:*)
  - Read
argument-hint: [version]
last_modified: 2026-01-19
source: ace-git
integration:
  targets:
    - claude
    - codex
    - gemini
    - opencode
    - pi
  providers: {}
assign:
  source: wfi://git/reorganize-commits
  steps:
    - name: reorganize-commits
      description: Reorganize commits into logical groups for clean history
      intent:
        phrases:
          - "reorganize commits"
          - "clean up commits"
          - "rewrite commit history"
          - "tidy commit history"
      tags: [git, history, cleanup]
skill:
  kind: workflow
  execution:
    workflow: wfi://git/reorganize-commits
---

Load and run `ace-bundle wfi://git/reorganize-commits` in the current project, then follow the loaded workflow as the source of truth and execute it end-to-end instead of only summarizing it.
