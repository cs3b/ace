---
name: as-release
description: Release modified ACE packages with coordinated package and root changelog
  updates
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
skill:
  kind: workflow
  execution:
    workflow: wfi://release/publish
context: fork
model: gpt-5.3-codex-spark
---

read and run `ace-bundle wfi://release/publish`
