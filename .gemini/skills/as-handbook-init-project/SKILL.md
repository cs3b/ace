---
name: as-handbook-init-project
description: Initialize Project Structure
user-invocable: true
allowed-tools:
- Bash(ace-handbook:*)
- Bash(ace-bundle:*)
- Bash(ace-git-commit:*)
- Read
- Write
- Edit
- Grep
argument-hint:
- project-path
last_modified: 2026-01-10
source: ace-handbook
skill:
  kind: workflow
  execution:
    workflow: wfi://handbook/init-project
---

read and run `ace-bundle wfi://handbook/init-project`
