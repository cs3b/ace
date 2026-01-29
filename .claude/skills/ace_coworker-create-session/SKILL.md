---
name: ace:coworker-create-session
description: Create a new coworker workflow session from job.yaml
# bundle: wfi://create-coworker-session
# agent: general-purpose
user-invocable: true
allowed-tools:
  - Bash(ace-coworker:*)
  - Bash(ace-bundle:*)
  - Read
  - Write
  - AskUserQuestion
argument-hint: "[path/to/job.yaml]"
last_modified: 2026-01-28
source: ace-coworker
---

read and run `ace-bundle wfi://create-coworker-session`
