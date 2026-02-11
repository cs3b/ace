---
tc-id: TC-005
title: --no-report Suppresses Output
---

## Objective

Verify that `--no-report` flag prevents report generation entirely — no "Reports:" in output and no .cache/ace-lint/ directory created.

## Steps

1. Clean previous reports and run with --no-report
   ```bash
   rm -rf .cache/ace-lint
   OUTPUT=$(ace-lint lint --no-report valid.rb 2>&1)
   EXIT_CODE=$?
   echo "$OUTPUT"
   echo "Exit code: $EXIT_CODE"
   ```

2. Verify exit code is 0
   ```bash
   [ "$EXIT_CODE" -eq 0 ] && echo "PASS: Exit code is 0" || echo "FAIL: Expected 0, got $EXIT_CODE"
   ```

3. Verify no report path in output
   ```bash
   ! echo "$OUTPUT" | grep -qE "Reports?:" && echo "PASS: No report path in output" || echo "FAIL: Report path found in output"
   ```

4. Verify no cache directory created
   ```bash
   ! test -d .cache/ace-lint && echo "PASS: No cache directory" || echo "FAIL: Cache directory exists"
   ```

## Expected

- Exit code: 0
- Output does NOT contain "Reports:" line
- .cache/ace-lint/ directory is NOT created
