---
name: ace:coworker-prepare
description: Prepare job.yaml from preset or informal instructions
# bundle: wfi://prepare-coworker-job
# agent: general-purpose
user-invocable: true
allowed-tools:
  - Bash(ls:*)
  - Bash(cat:*)
  - Bash(ace-bundle:*)
  - Read
  - Write
  - AskUserQuestion
argument-hint: "[preset-name] [--taskref value] [--output path]"
last_modified: 2026-01-28
source: ace-coworker
---

read and run `ace-bundle wfi://prepare-coworker-job`
