---
name: as-release-update-changelog
description: Update CHANGELOG.md with recent changes following Keep a Changelog format
user-invocable: true
allowed-tools:
- Bash(ace-git:*)
- Bash(ace-bundle:*)
- Read
- Edit
argument-hint:
- change-description
last_modified: 2026-01-10
source: ace-handbook
skill:
  kind: workflow
  execution:
    workflow: wfi://release/update-changelog
context: fork
model: gpt-5.3-codex-spark
---

## Instructions

- You are working in a forked execution context for the current project.
- Run `mise exec -- ace-bundle wfi://release/update-changelog` in the current project to load the workflow instructions.
- Read the loaded workflow and execute it end-to-end in this forked context.
- Follow the workflow as the source of truth.
- Do the work described by the workflow instead of only summarizing it.
- Return results from the executed workflow, not a summary of the workflow text.
