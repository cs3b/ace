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

Prepare:
- `$INTENT`: prepare describe intent of recent changes
- `$CHANGED_FILES`: list of files that have been changed in this session

Run commandline:
```bash
ace-llm codex:spark@yolo "$INTENT

$CHANGED_FILES

read and run \`ace-bundle wfi://git/commit\`"
```
