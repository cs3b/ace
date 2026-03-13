---
name: as-test-verify-suite
description: Verify test suite health and enforce performance budgets
user-invocable: true
allowed-tools:
- Bash(ace-bundle:*)
- Bash(ace-test:*)
- Bash(ace-nav:*)
- Read
- Write
- Edit
- Grep
- Glob
argument-hint:
- package | path | mode:quick|standard|deep
last_modified: 2026-01-31
source: ace-test
skill:
  kind: workflow
  execution:
    workflow: wfi://test/verify-suite
context: fork
model: gpt-5.3-codex-spark
---

## Instructions

- You are working in a forked execution context for the current project.
- Run `mise exec -- ace-bundle wfi://test/verify-suite` in the current project to load the workflow instructions.
- Read the loaded workflow and execute it end-to-end in this forked context.
- Follow the workflow as the source of truth.
- Do the work described by the workflow instead of only summarizing it.
- Return results from the executed workflow, not a summary of the workflow text.
