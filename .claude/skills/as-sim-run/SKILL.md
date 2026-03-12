---
name: as-sim-run
description: Run scenario simulation with provider comparison
user-invocable: true
allowed-tools:
- Bash(ace-sim:*)
- Bash(ace-bundle:*)
- Read
- TodoWrite
argument-hint: "[--preset NAME] [--source PATH]"
last_modified: 2026-02-28
source: ace-sim
skill:
  kind: workflow
  execution:
    workflow: wfi://sim/run
---

read and run `ace-bundle wfi://sim/run`
