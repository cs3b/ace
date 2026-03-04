---
name: ace-test-plan
description: Create a test responsibility map and coverage plan before writing code
# context: no-fork
# agent: general-purpose
user-invocable: true
allowed-tools:
  - Bash(ace-bundle:*)
  - Bash(ace-test:*)
  - Bash(ace-nav:*)
  - Read
  - Write
  - Edit
  - Grep
  - Glob
argument-hint: [feature | package | task]
last_modified: 2026-01-31
source: ace-test
---

read and run `ace-bundle wfi://test/plan`
