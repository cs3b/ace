---
name: as-git-rebase
description: Rebase with CHANGELOG preservation
# bundle: wfi://git/rebase
# context: no-fork
# agent: Bash
user-invocable: true
allowed-tools:
  - Bash(ace-git:*)
  - Bash(ace-bundle:*)
  - Read
  - Edit
  - Write
argument-hint: [target-branch]
last_modified: 2026-01-10
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
  source: wfi://git/rebase
  steps:
  - name: rebase-with-target
    description: Rebase current branch onto the target branch
    intent:
      phrases:
        - "rebase with target branch"
        - "rebase with main"
        - "rebase with origin main"
        - "rebase onto main"
        - "sync with main"
    tags: [git, history, rebase]
skill:
  kind: workflow
  execution:
    workflow: wfi://git/rebase
---

Load and run `ace-bundle wfi://git/rebase` in the current project, then follow the loaded workflow as the source of truth and execute it end-to-end instead of only summarizing it.
