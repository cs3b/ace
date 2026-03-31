---
name: as-release-rubygems-publish
description: Publish ACE gems to RubyGems.org in dependency order
user-invocable: true
allowed-tools:
- Bash(bundle:*)
- Bash(gem:*)
- Bash(ace-bundle:*)
- Read
argument-hint: "[gem-name...] [--dry-run]"
last_modified: 2026-03-29
source: ace-handbook
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

- After live publishing, recommend running `wfi://release/rubygems-verify-install` for installation verification.
