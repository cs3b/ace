---
name: as-test-review
description: Review tests for layer fit, mock quality, and performance
# context: no-fork
# agent: general-purpose
user-invocable: true
allowed-tools:
  - Bash(ace-bundle:*)
  - Bash(ace-test:*)
  - Bash(ace-nav:*)
  - Read
  - Write
  - Edit
  - Grep
  - Glob
argument-hint: [paths | PR-number]
last_modified: 2026-01-31
source: ace-test
---

Load and follow the test review checklist guide:

```bash
ace-bundle guide://test-review-checklist
```

## Review Focus Areas

1. **Layer Fit** - Is the test at the correct layer (atom/molecule/organism)?
2. **Mock Quality** - Are mocks minimal and appropriate?
3. **Performance** - Does the test run within budget (<100ms atoms, <500ms molecules)?
4. **Coverage** - Does the test cover the right responsibilities?

Reference the test responsibility map guide for layer decisions:
```bash
ace-bundle guide://test-responsibility-map
```
