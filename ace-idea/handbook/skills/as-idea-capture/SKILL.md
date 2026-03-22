---
name: as-idea-capture
description: Capture development idea to structured idea file with tags
# bundle: wfi://idea/capture
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
source: ace-idea
skill:
  kind: workflow
  execution:
    workflow: wfi://idea/capture

---

Load and run `ace-bundle wfi://idea/capture` in the current project, then follow the loaded workflow as the source of truth and execute it end-to-end instead of only summarizing it.
