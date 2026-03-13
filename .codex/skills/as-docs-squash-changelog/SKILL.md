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
skill:
  kind: workflow
  execution:
    workflow: wfi://docs/squash-changelog
context: fork
model: gpt-5.3-codex-spark
---

## Instructions

- You are working in a forked execution context for the current project.
- Run `mise exec -- ace-bundle wfi://docs/squash-changelog` in the current project to load the workflow instructions.
- Read the loaded workflow and execute it end-to-end in this forked context.
- Follow the workflow as the source of truth.
- Do the work described by the workflow instead of only summarizing it.
- Return results from the executed workflow, not a summary of the workflow text.
