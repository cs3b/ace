---
name: as-github-pr-create
description: Create GitHub pull request with generated description and summary
# bundle: wfi://github/pr/create
# agent: general-purpose
user-invocable: true
allowed-tools:
  - Bash(ace-git:*)
  - Bash(ace-bundle:*)
  - Bash(gh:*)
  - Read
argument-hint: pr-type
last_modified: 2026-01-10
source: ace-git
integration:
  targets:
    - claude
    - codex
    - gemini
    - opencode
    - pi
  providers:
    claude:
      frontmatter:
        context: fork
        model: haiku
assign:
  source: wfi://github/pr/create
  phases:
    - name: create-pr
      description: Create a pull request for the implemented changes
      intent:
        phrases:
          - "create pr"
          - "create a pr"
          - "open pr"
          - "open pull request"
      tags: [git, pr, publishing]
skill:
  kind: workflow
  execution:
    workflow: wfi://github/pr/create
---

## Arguments

Use the skill `argument-hint` values as the explicit inputs for this skill.

## Variables

None

## Execution

- You are working in the current project.
- Run `mise exec -- ace-bundle wfi://github/pr/create` in the current project to load the workflow instructions.
- Read the loaded workflow and execute it end-to-end in this project.
- Follow the workflow as the source of truth.
- Do the work described by the workflow instead of only summarizing it.
- When the workflow requires edits, tests, or commits, perform them in this project.
