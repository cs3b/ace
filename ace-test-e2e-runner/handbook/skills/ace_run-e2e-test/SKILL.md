---
name: ace:run-e2e-test
description: Run E2E tests via ace-e2e-test CLI
user-invocable: true
allowed-tools:
  - Bash(ace-*:*)
  - Bash(find:*)
  - Bash(ruby:*)
  - Read
  - Write
  - Glob
  - Grep
argument-hint: "[package] [test-id]"
last_modified: 2026-02-04
source: ace-test-e2e-runner
---

Run: `ace-e2e-test $ARGUMENTS`

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
