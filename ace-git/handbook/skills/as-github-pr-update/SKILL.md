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
  providers:
    codex:
      frontmatter:
        context: fork
        model: gpt-5.3-codex-spark
skill:
  kind: workflow
  execution:
    workflow: wfi://github/pr/update
---

read and run `ace-bundle wfi://github/pr/update`
