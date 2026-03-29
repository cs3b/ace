---
name: as-github-release-publish
description: Finalize unreleased changelog and create GitHub releases
user-invocable: true
allowed-tools:
- Bash(gh:*)
- Bash(ace-bundle:*)
- Bash(ace-git-commit:*)
- Read
- Edit
argument-hint: "[version-or-range] [--since duration] [--group-by package|date] [--category-order
  fixed,added,changed,technical] [--dry-run]"
last_modified: 2026-03-21
source: ace-git
assign:
  source: wfi://github/release-publish
  steps:
  - name: publish-releases
    description: Create GitHub releases from unpublished changelog entries
    intent:
      phrases:
      - publish github releases
      - create github releases
      - publish releases
    tags:
    - git
    - github
    - release
    - publishing
skill:
  kind: workflow
  execution:
    workflow: wfi://github/release-publish
context: fork
model: haiku
---

## Arguments

Use the skill `argument-hint` values as the explicit inputs for this skill.

## Variables

None

## Execution

- You are working in the current project.
- Run `ace-bundle wfi://github/release-publish` in the current project to load the workflow instructions.
- Read the loaded workflow and execute it end-to-end in this project.
- Follow the workflow as the source of truth.
- Do the work described by the workflow instead of only summarizing it.
- When the workflow requires edits, tests, or commits, perform them in this project.
