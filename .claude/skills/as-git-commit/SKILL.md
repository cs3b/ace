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
context: fork
model: haiku
---

## Instructions

- You are working in a forked execution context for the current project.
- Run `mise exec -- ace-bundle wfi://git/commit` in the current project to load the workflow instructions.
- Read the loaded workflow and execute it end-to-end in this forked context.
- Follow the workflow as the source of truth.
- Do the work described by the workflow instead of only summarizing it.
- Return results from the executed workflow, not a summary of the workflow text.
