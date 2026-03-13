---
name: as-git-commit
description: Generate intelligent git commit message from staged or all changes
# bundle: wfi://git/commit
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
      context: ace-llm
      ace-llm: codex:spark@yolo
      prompt_context:
        intention: describe intent of recent changes
        changed_files: list files changed in this session
skill:
  kind: workflow
  execution:
    workflow: wfi://git/commit
---

read and run `ace-bundle wfi://git/commit`
