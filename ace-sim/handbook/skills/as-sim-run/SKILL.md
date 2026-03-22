---
name: as-sim-run
description: Run scenario simulation with provider comparison
# bundle: wfi://sim/run
# agent: general-purpose
user-invocable: true
allowed-tools:
  - Bash(ace-sim:*)
  - Bash(ace-bundle:*)
  - Read
  - TodoWrite
argument-hint: "[--preset NAME] [--source PATH]"
last_modified: 2026-02-28
source: ace-sim
integration:
  targets:
    - claude
    - codex
    - gemini
    - opencode
    - pi
  providers: {}
skill:
  kind: workflow
  execution:
    workflow: wfi://sim/run
---

Load and run `ace-bundle wfi://sim/run` in the current project, then follow the loaded workflow as the source of truth and execute it end-to-end instead of only summarizing it.
