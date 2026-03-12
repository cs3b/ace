---
name: as-docs-squash-changelog
description: Squash multiple CHANGELOG.md entries into one before merge
# bundle: wfi://docs/squash-changelog
# agent: general-purpose
user-invocable: true
allowed-tools:
  - Bash(ace-git:*)
  - Bash(ace-bundle:*)
  - Bash(gh:*)
  - Read
  - Edit
  - Grep
argument-hint: "[target-branch]"
last_modified: 2026-03-10
source: ace-docs
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
    workflow: wfi://docs/squash-changelog
---

read and run `ace-bundle wfi://docs/squash-changelog`
