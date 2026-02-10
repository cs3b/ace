---
tc-id: TC-004
title: Exit Code 2 on Syntax Error
---

## Objective

Verify that doctor returns exit code 2 for YAML syntax errors.

Known issue: `ace-lint doctor` currently returns exit code 0 instead of expected exit code 2 when encountering YAML syntax errors. This is a code bug in the doctor command's exit code handling, not a test issue.

## Steps

1. Run doctor with syntax error config
   ```bash
   cd syntax-error
   OUTPUT=$(ace-lint doctor 2>&1)
   EXIT_CODE=$?
   echo "Exit code: $EXIT_CODE"
   echo "$OUTPUT"
   ```

2. Verify exit code is 2
   ```bash
   [ "$EXIT_CODE" -eq 2 ] && echo "PASS: Exit code 2 for syntax error" || echo "FAIL: Expected 2, got $EXIT_CODE"
   ```

## Expected

- Exit code: 2 (indicates configuration error)
