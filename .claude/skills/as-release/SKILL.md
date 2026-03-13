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
model: haiku
---

## Instructions

- You are working in a forked execution context for the current project.
- Run `mise exec -- ace-bundle wfi://release/publish` in the current project to load the workflow instructions.
- Read the loaded workflow and execute it end-to-end in this forked context.
- Follow the workflow as the source of truth.
- Do the work described by the workflow instead of only summarizing it.
- Return results from the executed workflow, not a summary of the workflow text.
