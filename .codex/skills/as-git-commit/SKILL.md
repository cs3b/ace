---
name: as-git-commit
description: Generate intelligent git commit message from staged or all changes
user-invocable: true
allowed-tools:
- Bash(ace-git-commit:*)
- Bash(ace-git:*)
- Bash(ace-bundle:*)
- Read
argument-hint:
- intention
last_modified: 2026-01-10
source: ace-git-commit
skill:
  kind: workflow
  execution:
    workflow: wfi://git/commit
---

## Variables

- INTENTION
- CHANGED_FILES

## Instructions

- If INTENTION was provided explicitly, use it. Otherwise, describe intent of recent changes.
- If CHANGED_FILES was provided explicitly, use it. Otherwise, list files changed in this session.

Run:
```bash
ace-llm codex:spark@yolo "INTENTION

CHANGED_FILES

read and run \`ace-bundle wfi://git/commit\`"
```
