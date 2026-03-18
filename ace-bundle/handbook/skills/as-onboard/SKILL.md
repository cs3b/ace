---
name: as-onboard
description: Load full project context bundle for onboarding to the codebase
# bundle: wfi://onboard
# agent: general-purpose
user-invocable: true
allowed-tools:
  - Bash(ace-bundle:*)
  - Read
argument-hint: [preset]
last_modified: 2026-01-17
source: ace-bundle
integration:
  targets:
    - claude
    - codex
    - gemini
    - opencode
    - pi
  providers: {}
assign:
  source: wfi://onboard
  steps:
    - name: onboard
      description: Load project context and understand the codebase
      tags: [setup, context-loading]
skill:
  kind: workflow
  execution:
    workflow: wfi://onboard
---

Load and run `mise exec -- ace-bundle wfi://onboard` in the current project, then follow the loaded workflow as the source of truth and execute it end-to-end instead of only summarizing it.
