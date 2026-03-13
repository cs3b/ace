---
name: as-demo-record
description: Record terminal demos from VHS tapes or inline commands
user-invocable: true
allowed-tools:
- Bash(ace-demo:*)
- Bash(ace-bundle:*)
- Read
argument-hint: "<tape|name> [--pr <number>] [-- commands...]"
last_modified: 2026-03-05
source: ace-demo
skill:
  kind: workflow
  execution:
    workflow: wfi://demo/record
context: fork
model: gpt-5.3-codex-spark
---

## Instructions

- You are working in a forked execution context for the current project.
- Run `mise exec -- ace-bundle wfi://demo/record` in the current project to load the workflow instructions.
- Read the loaded workflow and execute it end-to-end in this forked context.
- Follow the workflow as the source of truth.
- Do the work described by the workflow instead of only summarizing it.
- Return results from the executed workflow, not a summary of the workflow text.
