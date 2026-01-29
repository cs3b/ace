---
name: ace:work-on-task
description: Execute task implementation with context loading and change commits
context: fork
# agent: general-purpose
user-invocable: true
allowed-tools:
  - Bash(ace-taskflow:*)
  - Bash(ace-bundle:*)
  - Bash(ace-git-commit:*)
  - Read
  - Write
  - Edit
  - TodoWrite
  - Task
argument-hint: [task-id like 123]
last_modified: 2026-01-28
source: ace-taskflow
---

## Load Project Info

- read and run `ace-bundle project`

## Do the Work

- read and run `ace-bundle wfi://work-on-task` with earlier defined task

## Report

Return a structured summary to the parent agent:

- **Task**: task ID and title
- **Status**: completed | partial | blocked
- **Changes**: list of files modified and what changed
- **Commits**: commit hashes and messages created during this session
- **Issues**: any problems encountered or deferred decisions
