---
tc-id: TC-001
title: Valid File Exits with Code 0
---

## Objective

Verify that linting a valid file returns exit code 0.

## Steps

1. Lint a valid markdown file and verify exit code
   ```bash
   ace-lint lint valid.md
   EXIT_CODE=$?
   echo "Exit code: $EXIT_CODE"
   [ "$EXIT_CODE" -eq 0 ] && echo "PASS: Exit code is 0" || echo "FAIL: Expected 0, got $EXIT_CODE"
   ```

## Expected

- Exit code: 0
- Output contains "passed" indication
