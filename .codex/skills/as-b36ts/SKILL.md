---
name: as-b36ts
description: ENCODE and DECODE timestamps to/from compact Base36 IDs
user-invocable: true
allowed-tools:
- Bash(ace-b36ts:*)
- Bash(ace-bundle:*)
- Read
argument-hint: "[encode|decode|config] [value] [options]"
last_modified: 2026-03-09
source: ace-b36ts
skill:
  kind: capability
  execution:
    workflow: wfi://b36ts
context: fork
model: gpt-5.3-codex-spark
---

## Instructions

- You are working in a forked execution context for the current project.
- Run `mise exec -- ace-bundle wfi://b36ts` in the current project to load the workflow instructions.
- Read the loaded workflow and execute it end-to-end in this forked context.
- Follow the workflow as the source of truth.
- Do the work described by the workflow instead of only summarizing it.
- Return results from the executed workflow, not a summary of the workflow text.
