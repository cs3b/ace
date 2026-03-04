---
name: ace-onboard
description: Load full project context bundle for onboarding to the codebase
user-invocable: true
allowed-tools:
  - Bash(ace-bundle)
  - Read
argument-hint: [preset]
last_modified: 2026-01-17
source: ace-meta
---

## VARIABLE 

$preset: project 

## INSTRUCTION

- Run `ace-bundle $preset`, 
- read the whole output (including all referenced file contents).
- summarize the current state of the project
