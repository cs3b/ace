---
name: as-release-bump-version
description: Increment gem version following semver with CHANGELOG updates
# bundle: wfi://release/bump-version
# context: fork for codex
# agent: Bash
user-invocable: true
allowed-tools:
  - Bash(ace-git:*)
  - Bash(ace-bundle:*)
  - Read
  - Edit
argument-hint: "[package-name] [patch|minor|major]"
last_modified: 2026-01-10
source: ace-handbook
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
    workflow: wfi://release/bump-version
---

read and run `ace-bundle wfi://release/bump-version`
