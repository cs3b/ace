---
name: as-release
description: Release modified ACE packages with coordinated package and root changelog updates
# bundle: wfi://release/publish
# agent: general-purpose
user-invocable: true
allowed-tools:
  - Bash(ace-git:*)
  - Bash(ace-git-commit:*)
  - Bash(ace-bundle:*)
  - Bash(bundle:*)
  - Read
  - Edit
argument-hint: package-name... bump-level
last_modified: 2026-03-08
source: ace-handbook
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
skill:
  kind: workflow
  execution:
    workflow: wfi://release/publish
---

read and run `ace-bundle wfi://release/publish`
