---
tc-id: TC-002
title: Error on Nonexistent Task
---

## Objective

Verify that `ace-overseer work-on --task 999` exits with a non-zero code when the task does not exist in the taskflow structure.

## Steps

1. Run work-on with a nonexistent task ID
   ```bash
   OUTPUT=$(ace-overseer work-on --task 999 2>&1)
   EXIT_CODE=$?
   echo "Exit code: $EXIT_CODE"
   echo "Output: $OUTPUT"
   ```

2. Verify exit code is non-zero
   ```bash
   [ "$EXIT_CODE" -ne 0 ] && echo "PASS: Non-zero exit code ($EXIT_CODE)" || echo "FAIL: Expected non-zero, got $EXIT_CODE"
   ```

3. Verify error message references the task
   ```bash
   echo "$OUTPUT" | grep -qiE "not found|no task|unknown|999" && echo "PASS: Error message references missing task" || echo "FAIL: No relevant error message"
   ```

## Expected

- Exit code: non-zero
- Output contains error message indicating task 999 was not found
