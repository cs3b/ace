---
name: as-e2e-plan-changes
description: Analyze coverage matrix and produce a concrete E2E test change plan
# bundle: wfi://e2e/plan-changes
# agent: general-purpose
user-invocable: true
allowed-tools:
  - Bash(ace-bundle:*)
  - Read
  - Glob
  - Grep
  - Skill
argument-hint: "<package> [--review-report <path>] [--scope <scenario-id>]"
last_modified: 2026-02-11
source: ace-test-runner-e2e
integration:
  targets:
    - claude
    - codex
    - gemini
    - opencode
    - pi
  providers: {}
skill:
  kind: workflow
  execution:
    workflow: wfi://e2e/plan-changes
---

Load and run `mise exec -- ace-bundle wfi://e2e/plan-changes` in the current project, then follow the loaded workflow as the source of truth and execute it end-to-end instead of only summarizing it.
