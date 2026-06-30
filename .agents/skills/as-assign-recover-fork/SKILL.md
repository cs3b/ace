---
name: as-assign-recover-fork
description: Recover from fork-run failures in assignment execution
user-invocable: true
allowed-tools:
- Bash(ace-assign:*)
- Bash(ace-bundle:*)
- Bash(ace-git-commit:*)
- Bash(git:*)
- Read
- Write
- AskUserQuestion
argument-hint: "<assignment-id>@<fork-root>"
source: ace-assign
skill:
  kind: workflow
  execution:
    workflow: wfi://assign/recover-fork
---

Load and run `ace-bundle wfi://assign/recover-fork` in the current project, then follow the loaded workflow as the source of truth and execute it end-to-end instead of only summarizing it.
