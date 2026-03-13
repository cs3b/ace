---
name: as-prompt-prep
description: Run ace-prompt-prep and follow the printed instructions
user-invocable: true
allowed-tools:
- Bash(ace-prompt-prep:*)
- Bash(ace-bundle:*)
- Read
last_modified: 2026-01-17
source: ace-prompt-prep
skill:
  kind: workflow
  execution:
    workflow: wfi://prompt-prep
context: fork
model: gpt-5.3-codex-spark
---

## Instructions

- You are working in a forked execution context for the current project.
- Run `mise exec -- ace-bundle wfi://prompt-prep` in the current project to load the workflow instructions.
- Read the loaded workflow and execute it end-to-end in this forked context.
- Follow the workflow as the source of truth.
- Do the work described by the workflow instead of only summarizing it.
- Return results from the executed workflow, not a summary of the workflow text.
