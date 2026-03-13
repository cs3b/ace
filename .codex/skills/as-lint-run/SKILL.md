---
name: as-lint-run
description: Run ace-lint on project files with optional autofix and report
user-invocable: true
allowed-tools:
- Bash(ace-lint:*)
- Bash(ace-bundle:*)
- Read
argument-hint: "[file-pattern] [--fix] [--report]"
last_modified: 2026-03-10
source: ace-lint
skill:
  kind: workflow
  execution:
    workflow: wfi://lint/run
context: fork
model: gpt-5.3-codex-spark
---

## Instructions

- You are working in a forked execution context for the current project.
- Run `mise exec -- ace-bundle wfi://lint/run` in the current project to load the workflow instructions.
- Read the loaded workflow and execute it end-to-end in this forked context.
- Follow the workflow as the source of truth.
- Do the work described by the workflow instead of only summarizing it.
- Return results from the executed workflow, not a summary of the workflow text.
