---
tc-id: TC-003
title: Explicit --output stdio Overrides Auto
---

## Objective

Verify that `--output stdio` forces large content to stdout, overriding the auto-format threshold.

## Steps

1. Load large preset with explicit stdio output
   ```bash
   OUTPUT=$(ace-bundle large-test --output stdio 2>&1)
   EXIT_CODE=$?
   echo "Exit code: $EXIT_CODE"
   [ "$EXIT_CODE" -eq 0 ] && echo "PASS: Exit code is 0" || echo "FAIL: Expected 0, got $EXIT_CODE"
   echo "$OUTPUT" | grep -q "# Large Test Content" && echo "PASS: Content output directly" || echo "FAIL: Content not in stdout"
   ! echo "$OUTPUT" | grep -q "Bundle saved" && echo "PASS: No cache message" || echo "FAIL: Unexpected cache message"
   ```

## Expected

- Exit code: 0
- Output contains "# Large Test Content" directly in stdout
- Output does NOT contain "Bundle saved"
