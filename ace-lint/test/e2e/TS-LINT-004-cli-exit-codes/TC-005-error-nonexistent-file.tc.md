---
tc-id: TC-005
title: Error - Nonexistent File
---

## Objective

Verify that ace-lint handles nonexistent files gracefully.

## Steps

1. Attempt to lint a nonexistent file and verify error handling
   ```bash
   OUTPUT=$(ace-lint lint does_not_exist.md 2>&1)
   EXIT_CODE=$?
   echo "Exit code: $EXIT_CODE"
   echo "Output: $OUTPUT"
   [ "$EXIT_CODE" -ne 0 ] && echo "PASS: Correct non-zero exit code" || echo "FAIL: Expected non-zero exit"
   echo "$OUTPUT" | grep -qi "not found\|no such file\|does not exist\|error" && echo "PASS: Error message present" || echo "FAIL: No error message"
   ```

## Expected

- Exit code: non-zero
- Output contains error message about missing file
