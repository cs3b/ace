---
name: as-release
description: Release modified ACE packages with coordinated package and root changelog
  updates
user-invocable: true
allowed-tools:
- Bash(ace-git:*)
- Bash(ace-git-commit:*)
- Bash(ace-bundle:*)
- Bash(bundle:*)
- Read
- Edit
argument-hint: package-name... bump-level
last_modified: 2026-03-08
source: ace-handbook
skill:
  kind: workflow
  execution:
    workflow: wfi://release/publish
---

## Arguments

Use the skill `argument-hint` values as the explicit inputs for this skill.

## Variables

None

## Execution

- You are working in the current project.
- Run `ace-bundle wfi://release/publish` in the current project to load the workflow instructions.
- Read the loaded workflow and execute it end-to-end in this project.
- Follow the workflow as the source of truth.
- If releasing a package forces dependent ACE gemspec constraints to move forward, auto-release those follower
  packages with a `patch` bump unless the caller explicitly selected a different bump for them.
- Do the work described by the workflow instead of only summarizing it.
- When the workflow requires edits, tests, or commits, perform them in this project.
