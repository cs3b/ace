---
name: as-release-bump-version
description: Increment gem version following semver with CHANGELOG updates
user-invocable: true
allowed-tools:
- Bash(ace-git:*)
- Bash(ace-bundle:*)
- Read
- Edit
argument-hint: "[package-name] [patch|minor|major]"
last_modified: 2026-01-10
source: ace-handbook
skill:
  kind: workflow
  execution:
    workflow: wfi://release/bump-version
context: fork
model: gpt-5.3-codex-spark
---

## Instructions

- You are working in a forked execution context for the current project.
- Run `mise exec -- ace-bundle wfi://release/bump-version` in the current project to load the workflow instructions.
- Read the loaded workflow and execute it end-to-end in this forked context.
- Follow the workflow as the source of truth.
- Do the work described by the workflow instead of only summarizing it.
- Return results from the executed workflow, not a summary of the workflow text.
