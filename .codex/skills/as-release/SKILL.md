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
---

Prepare:
- `$INTENT`: prepare describe intent of recent changes
- `$CHANGED_FILES`: list of files that have been changed in this session

Run commandline:
```bash
ace-llm codex:spark@yolo "$INTENT

$CHANGED_FILES

read and run \`ace-bundle wfi://release/publish\`"
```
