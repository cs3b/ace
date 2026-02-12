---
tc-id: TC-002
title: Error - Invalid --after Reference
---

## Objective

Verify that `add --after` with an invalid phase number fails with a clear error showing available phases.

## Steps

1. Create assignment for testing
   ```bash
   ace-assign create job.yaml
   ASSIGNMENT_DIR=$(find "$CACHE_BASE" -maxdepth 1 -mindepth 1 -type d | sort | tail -1)
   ```

2. Attempt to add phase with invalid --after reference
   ```bash
   ADD_OUTPUT=$(ace-assign add test-step --after 999 -i "Test instructions" 2>&1)
   ADD_EXIT=$?
   echo "Exit code: $ADD_EXIT"
   echo "Output: $ADD_OUTPUT"
   [ "$ADD_EXIT" -ne 0 ] && echo "PASS: Non-zero exit code" || echo "FAIL: Expected non-zero exit code"
   echo "$ADD_OUTPUT" | grep -qi "not found" && echo "PASS: Error mentions 'not found'" || echo "FAIL: Error should mention 'not found'"
   echo "$ADD_OUTPUT" | grep -qi "available" && echo "PASS: Error mentions available phases" || echo "FAIL: Error should mention available phases"
   echo "$ADD_OUTPUT" | grep -q "010" && echo "PASS: Available phases include 010" || echo "FAIL: Available phases should include 010"
   ```

## Expected

- Exit code: non-zero (error)
- Error message contains "not found"
- Error message shows available phase numbers (010, 020)
