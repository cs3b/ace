---
name: as-docs-squash-changelog
description: Squash multiple CHANGELOG.md entries into one before merge
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
skill:
  kind: workflow
  execution:
    workflow: wfi://docs/squash-changelog
context: fork
model: gpt-5.3-codex-spark
---

read and run `ace-bundle wfi://docs/squash-changelog`
