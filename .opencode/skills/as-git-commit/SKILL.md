---
name: as-git-commit
description: Generate intelligent git commit message from staged or all changes
user-invocable: true
allowed-tools:
- Bash(ace-git-commit:*)
- Bash(ace-git:*)
- Bash(ace-bundle:*)
- Read
argument-hint:
- intention
last_modified: 2026-01-10
source: ace-git-commit
skill:
  kind: workflow
  execution:
    workflow: wfi://git/commit
---

## Arguments

Use the skill `argument-hint` values as the explicit inputs for this skill.

## Variables

- INTENTION
- CHANGED_FILES

## Execution

- You are working in the current project.
- Run `mise exec -- ace-bundle wfi://git/commit` in the current project to load the workflow instructions.
- Read the loaded workflow and execute it end-to-end in this project.
- Follow the workflow as the source of truth.
- If `INTENTION` is provided explicitly, use it. Otherwise derive it from recent changes.
- If `CHANGED_FILES` are provided explicitly, use them. Otherwise derive them from changed files in this session.
- Do the work described by the workflow instead of only summarizing it.
- When the workflow requires edits, tests, or commits, perform them in this project.
