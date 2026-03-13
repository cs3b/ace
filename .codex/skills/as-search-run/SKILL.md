---
name: as-search-run
description: SEARCH code patterns and files - intelligent discovery
user-invocable: true
allowed-tools:
- Bash(ace-search:*)
- Bash(ace-bundle:*)
- Read
argument-hint: "[pattern] [--file|--content] [options]"
last_modified: 2026-01-09
source: ace-search
skill:
  kind: workflow
  execution:
    workflow: wfi://search/run
context: fork
model: gpt-5.3-codex-spark
---

## Instructions

- You are working in a forked execution context for the current project.
- Run `mise exec -- ace-bundle wfi://search/run` in the current project to load the workflow instructions.
- Read the loaded workflow and execute it end-to-end in this forked context.
- Follow the workflow as the source of truth.
- Do the work described by the workflow instead of only summarizing it.
- Return results from the executed workflow, not a summary of the workflow text.
