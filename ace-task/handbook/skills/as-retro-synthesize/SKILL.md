---
name: as-retro-synthesize
description: Synthesize retrospectives into patterns and improvement recommendations
# bundle: wfi://retro/synthesize
# context: no-fork
# agent: general-purpose
user-invocable: true
allowed-tools:
  - Bash(ace-task:*)
  - Bash(ace-bundle:*)
  - Bash(ace-git-commit:*)
  - Read
  - Write
  - Grep
  - TodoWrite
last_modified: 2026-01-10
source: ace-task
skill:
  kind: workflow
  execution:
    workflow: wfi://retro/synthesize

---

read and run `ace-bundle wfi://retro/synthesize`

