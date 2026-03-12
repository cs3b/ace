---
name: as-idea-prioritize
description: Prioritize and align development ideas with project goals and roadmap
user-invocable: true
allowed-tools:
- Bash(ace-task:*)
- Bash(ace-idea:*)
- Bash(ace-bundle:*)
- Bash(ace-git-commit:*)
- Read
- Write
- Edit
- TodoWrite
argument-hint:
- idea-pattern
last_modified: 2026-01-10
source: ace-task
skill:
  kind: workflow
  execution:
    workflow: wfi://idea/prioritize
---

read and run `ace-bundle wfi://idea/prioritize`
