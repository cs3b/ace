---
name: as-release-rubygems-publish
description: Publish ACE gems to RubyGems.org in dependency order
# bundle: wfi://release/rubygems-publish
# agent: general-purpose
user-invocable: true
allowed-tools:
  - Bash(bundle:*)
  - Bash(gem:*)
  - Bash(ace-bundle:*)
  - Read
argument-hint: "[gem-name...] [--dry-run]"
last_modified: 2026-04-10
source: ace-handbook
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
skill:
  kind: workflow
  execution:
    workflow: wfi://release/rubygems-publish
---

## Arguments

Use the skill `argument-hint` values as the explicit inputs for this skill.

## Variables

None

## Execution

- You are working in the current project.
- Run `ace-bundle wfi://release/rubygems-publish` in the current project to load the workflow instructions.
- Read the loaded workflow and execute it end-to-end in this project.
- Follow the workflow as the source of truth.
- Do the work described by the workflow instead of only summarizing it.
- When the workflow requires edits, tests, or commits, perform them in this project.

- After live publishing, recommend running `ace-test-e2e ace-monorepo-e2e TS-MONO-001` for installation verification.
