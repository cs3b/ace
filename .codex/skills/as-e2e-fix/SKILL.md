---
name: as-e2e-fix
description: Diagnose, fix, and rerun failing E2E tests systematically, generating failure analysis when needed
user-invocable: true
allowed-tools:
- Bash(ace-task:*)
- Bash(ace-bundle:*)
- Bash(ace-test:*)
- Bash(ace-test-suite:*)
- Bash(git:*)
- Read
- Write
- Edit
- Grep
- Glob
argument-hint: "[package] [test-id]"
last_modified: 2026-03-13
source: ace-test-runner-e2e
skill:
  kind: workflow
  execution:
    workflow: wfi://e2e/fix
---

Load and run `ace-bundle wfi://e2e/fix` in the current project, then follow the loaded workflow as the source of truth and execute it end-to-end instead of only summarizing it. If E2E failure analysis is missing or incomplete, generate it via `wfi://e2e/analyze-failures` as part of the fix workflow before applying changes.
