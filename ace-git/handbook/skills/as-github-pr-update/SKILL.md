---
name: as-github-pr-update
description: Update PR description based on current work
# bundle: wfi://github/pr/update
# agent: general-purpose
user-invocable: true
allowed-tools:
  - Bash(ace-git:*)
  - Bash(ace-bundle:*)
  - Bash(gh:*)
  - Read
  - Grep
argument-hint: pr-number
last_modified: 2026-01-10
source: ace-git
integration:
  targets:
    - claude
    - codex
    - gemini
    - opencode
    - pi
assign:
  source: wfi://github/pr/update
  phases:
    - name: update-pr-desc
      description: Update PR description with implementation summary and final state
      intent:
        phrases:
          - "update pr description"
          - "update pull request description"
          - "refresh pr description"
          - "sync pr description"
      tags: [git, pr, documentation]
skill:
  kind: workflow
  execution:
    workflow: wfi://github/pr/update
---

Load and run `mise exec -- ace-bundle wfi://github/pr/update` in the current project, then follow the loaded workflow as the source of truth and execute it end-to-end instead of only summarizing it.
