---
tc-id: TC-001
title: Error on Missing --task Flag
---

## Objective

Verify that `ace-overseer work-on` without the required `--task` flag exits with a non-zero code and prints a usage/error message.

## Steps

1. Run work-on without --task flag
   ```bash
   OUTPUT=$(ace-overseer work-on 2>&1)
   EXIT_CODE=$?
   echo "Exit code: $EXIT_CODE"
   echo "Output: $OUTPUT"
   ```

2. Verify exit code is non-zero
   ```bash
   [ "$EXIT_CODE" -ne 0 ] && echo "PASS: Non-zero exit code ($EXIT_CODE)" || echo "FAIL: Expected non-zero, got $EXIT_CODE"
   ```

3. Verify error or usage message in output
   ```bash
   echo "$OUTPUT" | grep -qiE "task|required|missing|usage" && echo "PASS: Error message mentions task flag" || echo "FAIL: No relevant error message"
   ```

## Expected

- Exit code: non-zero
- Output contains error/usage message referencing the --task flag
