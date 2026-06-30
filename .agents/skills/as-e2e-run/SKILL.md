---
name: as-e2e-run
description: Execute an E2E test scenario
user-invocable: true
allowed-tools:
- Bash(ace-bundle:*)
- Read
- Write
- Glob
- Grep
argument-hint: "[package] [test-id] [--run-id ID] [--sandbox PATH] [--env K=V]"
last_modified: 2026-02-11
source: ace-test-runner-e2e
skill:
  kind: workflow
  execution:
    workflow: wfi://e2e/run
---

<!-- Route to the appropriate workflow based on arguments -->
<!-- --sandbox present → focused execution workflow (pre-populated sandbox) -->
<!-- --sandbox absent  → full workflow (locate, setup, execute) -->

If `$ARGUMENTS` contains `--sandbox`:
  read and run `ace-bundle wfi://e2e/execute`


Otherwise:

  read and run `ace-bundle wfi://e2e/run`

ARGUMENTS: $ARGUMENTS

## Execution Context

- `/as-e2e-run ...` is a chat slash command, not a shell command.
- Do **not** run `/ace-...` in bash (this causes `command not found` and no reports).
- If slash commands are unavailable in the current environment, report that limitation explicitly in `Issues`.

## Subagent Return Contract

When invoked as a subagent (via a batch orchestrator such as `/as-assign-run-in-batches`), return a structured summary instead of verbose output:

Return `Test ID`, `Status`, `Passed`, `Failed`, `Total`, `Report Paths`, and `Issues`.

Do NOT include full report contents. Reports are written to disk; return only paths and summary counts for aggregation by the orchestrator.
