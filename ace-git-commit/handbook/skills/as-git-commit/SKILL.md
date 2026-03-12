---
name: as-git-commit
description: Generate intelligent git commit message from staged or all changes
# bundle: wfi://git/commit
# context: fork for claude/codex
# agent: Bash
user-invocable: true
allowed-tools:
  - Bash(ace-git-commit:*)
  - Bash(ace-git:*)
  - Bash(ace-bundle:*)
  - Read
argument-hint: [intention]
last_modified: 2026-01-10
source: ace-git-commit
integration:
  targets:
    - claude
    - codex
    - gemini
    - opencode
    - pi
  providers:
    claude:
      frontmatter:
        context: fork
        model: haiku
    codex:
      frontmatter:
        context: fork
        model: gpt-5.3-codex-spark
skill:
  kind: workflow
  execution:
    workflow: wfi://git/commit
---

read and run `ace-bundle wfi://git/commit`
