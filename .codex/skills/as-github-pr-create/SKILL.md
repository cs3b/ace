---
name: as-github-pr-create
description: Create GitHub pull request with generated description and summary
user-invocable: true
allowed-tools:
- Bash(ace-git:*)
- Bash(ace-bundle:*)
- Bash(gh:*)
- Read
argument-hint: pr-type
last_modified: 2026-01-10
source: ace-git
skill:
  kind: workflow
  execution:
    workflow: wfi://github/pr/create
context: fork
model: gpt-5.3-codex-spark
---

## Instructions

- You are working in a forked execution context for the current project.
- Run `mise exec -- ace-bundle wfi://github/pr/create` in the current project to load the workflow instructions.
- Read the loaded workflow and execute it end-to-end in this forked context.
- Follow the workflow as the source of truth.
- Do the work described by the workflow instead of only summarizing it.
- Return results from the executed workflow, not a summary of the workflow text.
