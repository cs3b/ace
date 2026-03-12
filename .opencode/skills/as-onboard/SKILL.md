---
name: as-onboard
description: Load full project context bundle for onboarding to the codebase
user-invocable: true
allowed-tools:
- Bash(ace-bundle:*)
- Read
argument-hint:
- preset
last_modified: 2026-01-17
source: ace-bundle
skill:
  kind: workflow
  execution:
    workflow: wfi://onboard
---

read and run `ace-bundle wfi://onboard`
