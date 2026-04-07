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
  steps:
    - name: onboard
      description: Load project context and understand the codebase
      prerequisites: []
      produces: [project-context]
      consumes: []
      context:
        default: null
        reason: "Onboarding needs access to the main conversation context"
      when_to_skip:
        - "Already onboarded in a previous assignment"
        - "Working in a context where project is already loaded"
      effort: light
      tags: [setup, context-loading]
skill:
  kind: workflow
  execution:
    workflow: wfi://onboard
---

Load and run `ace-bundle wfi://onboard` in the current project, then follow the loaded workflow as the source of truth and execute it end-to-end instead of only summarizing it.
