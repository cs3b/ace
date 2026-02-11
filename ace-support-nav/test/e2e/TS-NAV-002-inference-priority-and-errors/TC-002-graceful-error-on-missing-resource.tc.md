---
tc-id: TC-002
title: Graceful Error on Missing Resource
---

## Objective

Verify that requesting a non-existent resource produces a graceful error with an informative message, not a stack trace.

## Steps

1. Request a non-existent resource and capture output
   ```bash
   OUTPUT=$(ace-nav guide://nonexistent-resource 2>&1)
   EXIT_CODE=$?
   echo "$OUTPUT"
   echo "Exit code: $EXIT_CODE"
   ```

2. Verify non-zero exit code and informative error
   ```bash
   [ "$EXIT_CODE" -ne 0 ] && echo "PASS: Non-zero exit code ($EXIT_CODE)" || echo "FAIL: Expected non-zero, got 0"
   echo "$OUTPUT" | grep -qi "not found\|no match\|error\|unknown" && echo "PASS: Informative error message" || echo "FAIL: Error message not informative"
   echo "$OUTPUT" | grep -qv "\.rb:[0-9]" && echo "PASS: No stack trace" || echo "FAIL: Stack trace detected"
   ```

## Expected

- Exit code: non-zero (indicates resource not found)
- Error message is informative (not a Ruby stack trace)
- Suggests available resources or indicates no match found
