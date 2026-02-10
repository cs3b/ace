---
tc-id: TC-002
title: Invalid File Exits with Non-Zero Code
---

## Objective

Verify that linting a file with errors returns non-zero exit code.

## Steps

1. Lint a Ruby file with syntax errors and verify non-zero exit
   ```bash
   ace-lint lint syntax_error.rb
   EXIT_CODE=$?
   echo "Exit code: $EXIT_CODE"
   [ "$EXIT_CODE" -ne 0 ] && echo "PASS: Exit code is non-zero ($EXIT_CODE)" || echo "FAIL: Expected non-zero, got $EXIT_CODE"
   ```

## Expected

- Exit code: non-zero (typically 1)
- Output indicates lint errors (fatal severity from syntax error)
