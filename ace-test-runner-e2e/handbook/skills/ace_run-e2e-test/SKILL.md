---
name: ace:run-e2e-test
description: Execute an E2E test scenario
user-invocable: true
allowed-tools:
  - Bash(ace-*:*)
  - Bash(find:*)
  - Bash(ruby:*)
  - Read
  - Write
  - Glob
  - Grep
argument-hint: "[package] [test-id] [--run-id ID] [--sandbox PATH] [--env K=V]"
last_modified: 2026-02-11
source: ace-test-runner-e2e
---

<!-- Route to the appropriate workflow based on arguments -->
<!-- --sandbox present → focused execution workflow (pre-populated sandbox) -->
<!-- --sandbox absent  → full workflow (locate, setup, execute) -->

If `$ARGUMENTS` contains `--sandbox`:
  read and run `ace-bundle wfi://execute-e2e-test`
Otherwise:
  read and run `ace-bundle wfi://run-e2e-test`

ARGUMENTS: $ARGUMENTS

## Subagent Return Contract

When invoked as a subagent (via Task tool from `/ace:run-e2e-tests`), return a structured summary instead of verbose output:

```markdown
- **Test ID**: {test-id}
- **Status**: pass | fail | partial
- **Passed**: {count}
- **Failed**: {count}
- **Total**: {count}
- **Report Paths**: {timestamp}-{short-pkg}-{short-id}.*
- **Issues**: Brief description or "None"
```

Do NOT include full report contents. Reports are written to disk; return only paths and summary counts for aggregation by the orchestrator.
