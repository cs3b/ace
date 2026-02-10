---
tc-id: TC-003
title: --no-report Flag Disables Report Generation
---

## Objective

Verify that `--no-report` flag prevents report generation.

## Steps

1. Clean previous reports, run ace-lint with --no-report, and verify
   ```bash
   rm -rf .cache/ace-lint
   OUTPUT=$(ace-lint lint --no-report valid.md 2>&1)
   EXIT_CODE=$?
   echo "$OUTPUT"
   echo "Exit code: $EXIT_CODE"
   ! echo "$OUTPUT" | grep -qE "Reports?:" && echo "PASS: No report path in output" || echo "FAIL: Report path found"
   ! test -d .cache/ace-lint && echo "PASS: No cache directory" || echo "FAIL: Cache directory exists"
   ```

## Expected

- Exit code: 0
- Output does NOT contain report path
- .cache/ace-lint/ directory NOT created
