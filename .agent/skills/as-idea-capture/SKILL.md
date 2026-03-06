---
name: as-idea-capture
description: Capture development idea to structured idea file with tags
# context: no-fork
# agent: general-purpose
user-invocable: true
allowed-tools:
  - Bash(ace-task:*)
  - Bash(ace-idea:*)
  - Bash(ace-bundle:*)
  - Bash(ace-git-commit:*)
  - Write
  - TodoWrite
argument-hint: [idea-description]
last_modified: 2026-01-10
source: ace-task
---

read and run `ace-bundle wfi://idea/capture`

read and run `ace-bundle wfi://git/commit`
