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
assign:
  source: wfi://docs/squash-changelog
  steps:
  - name: squash-changelog
    description: Squash multiple changelog entries into one before merge
    intent:
      phrases:
      - squash changelog
      - squash changelog entries
      - consolidate changelog
      - merge changelog entries
    tags:
    - docs
    - changelog
    - release
skill:
  kind: workflow
  execution:
    workflow: wfi://docs/squash-changelog
---

Load and run `ace-bundle wfi://docs/squash-changelog` in the current project, then follow the loaded workflow as the source of truth and execute it end-to-end instead of only summarizing it.
