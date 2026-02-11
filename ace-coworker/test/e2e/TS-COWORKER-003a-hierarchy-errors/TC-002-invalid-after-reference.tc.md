---
tc-id: TC-002
title: Error - Invalid --after Reference
---

## Objective

Verify that `add --after` with an invalid job number fails with a clear error showing available jobs.

## Steps

1. Create session for testing
   ```bash
   ace-coworker create job.yaml
   SESSION_DIR=$(find "$CACHE_BASE" -maxdepth 1 -mindepth 1 -type d | sort | tail -1)
   ```

2. Attempt to add job with invalid --after reference
   ```bash
   ADD_OUTPUT=$(ace-coworker add test-step --after 999 -i "Test instructions" 2>&1)
   ADD_EXIT=$?
   echo "Exit code: $ADD_EXIT"
   echo "Output: $ADD_OUTPUT"
   [ "$ADD_EXIT" -ne 0 ] && echo "PASS: Non-zero exit code" || echo "FAIL: Expected non-zero exit code"
   echo "$ADD_OUTPUT" | grep -qi "not found" && echo "PASS: Error mentions 'not found'" || echo "FAIL: Error should mention 'not found'"
   echo "$ADD_OUTPUT" | grep -qi "available" && echo "PASS: Error mentions available jobs" || echo "FAIL: Error should mention available jobs"
   echo "$ADD_OUTPUT" | grep -q "010" && echo "PASS: Available jobs include 010" || echo "FAIL: Available jobs should include 010"
   ```

## Expected

- Exit code: non-zero (error)
- Error message contains "not found"
- Error message shows available job numbers (010, 020)
