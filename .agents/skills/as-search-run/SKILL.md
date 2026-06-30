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
---

## Arguments

Use the skill `argument-hint` values as the explicit inputs for this skill.

## Variables

None

## Execution

- You are working in the current project.
- Run `ace-bundle wfi://search/run` in the current project to load the workflow instructions.
- Read the loaded workflow and execute it end-to-end in this project.
- Follow the workflow as the source of truth.
- Do the work described by the workflow instead of only summarizing it.
- When the workflow requires edits, tests, or commits, perform them in this project.
