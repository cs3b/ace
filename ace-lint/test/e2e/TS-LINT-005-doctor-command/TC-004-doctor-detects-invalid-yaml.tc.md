---
tc-id: TC-004
title: Doctor Detects Invalid YAML (Exit Code 2)
---

## Objective

Verify that doctor command detects invalid YAML and returns exit code 2.

## Steps

1. Run doctor command with invalid YAML config
   ```bash
   cd invalid-config
   OUTPUT=$(ace-lint doctor 2>&1)
   EXIT_CODE=$?
   echo "Exit code: $EXIT_CODE"
   echo "$OUTPUT"
   ```

2. Verify exit code is 2 (error)
   ```bash
   [ "$EXIT_CODE" -eq 2 ] && echo "PASS: Exit code is 2 for YAML error" || echo "FAIL: Expected exit code 2, got $EXIT_CODE"
   ```

3. Check for error indication in output
   ```bash
   echo "$OUTPUT" | grep -qiE "error|invalid|syntax|parse" && echo "PASS: Error indication in output" || echo "INFO: Error not explicitly shown"
   ```

## Expected

- Exit code: 2 (indicates error)
- Output may indicate YAML syntax error
