---
name: as-release-update-changelog
description: Update CHANGELOG.md with recent changes following Keep a Changelog format
# bundle: wfi://release/update-changelog
# agent: general-purpose
user-invocable: true
allowed-tools:
  - Bash(ace-git:*)
  - Bash(ace-bundle:*)
  - Read
  - Edit
argument-hint: [change-description]
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
    workflow: wfi://release/update-changelog
---

read and run `ace-bundle wfi://release/update-changelog`
