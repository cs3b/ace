---
name: as-release-bump-version
description: Increment gem version following semver with CHANGELOG updates
# bundle: wfi://release/bump-version
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
skill:
  kind: workflow
  execution:
    workflow: wfi://release/bump-version
---

Load and run `mise exec -- ace-bundle wfi://release/bump-version` in the current project, then follow the loaded workflow as the source of truth and execute it end-to-end instead of only summarizing it.
