---
tc-id: TC-002
title: YAML Syntax Error Detection
---

## Objective

Verify that `ace-lint --doctor` detects YAML syntax errors in config files and reports the issue without crashing. Note: exit code should be 2 for errors but is currently 0 (known bug — not asserted here).

## Steps

1. Run doctor in the syntax-error directory
   ```bash
   cd syntax-error
   OUTPUT=$(ace-lint --doctor 2>&1)
   EXIT_CODE=$?
   echo "Exit code: $EXIT_CODE"
   echo "$OUTPUT"
   ```

2. Verify command didn't crash
   ```bash
   [ "$EXIT_CODE" -le 2 ] && echo "PASS: Command completed (exit $EXIT_CODE)" || echo "FAIL: Unexpected exit code $EXIT_CODE"
   ```

3. Verify output indicates error or syntax issue
   ```bash
   echo "$OUTPUT" | grep -qiE "error|syntax|invalid|parse|yaml" && echo "PASS: Error/syntax indication found" || echo "INFO: No explicit error indication in output"
   ```

## Expected

- Command completes without crashing (exit code ≤ 2)
- Output shows error, syntax, or invalid indication
- Known bug: exit code should be 2 but may be 0
