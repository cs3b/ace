---
tc-id: TC-001
title: Error - Advance Parent with Incomplete Children
---

## Objective

Verify that attempting to complete a parent job while children are incomplete fails with a clear error listing the incomplete children.

## Steps

1. Create session and add children under step 010
   ```bash
   ace-coworker create job.yaml
   SESSION_DIR=$(find "$CACHE_BASE" -maxdepth 1 -mindepth 1 -type d | sort | tail -1)
   ace-coworker add write-unit-tests --after 010 --child -i "Write unit tests for the feature"
   ace-coworker add write-integration-tests --after 010 --child -i "Write integration tests"
   [ -f "$SESSION_DIR/jobs/010.01-write-unit-tests.j.md" ] && echo "PASS: Child 010.01 exists" || echo "FAIL: Child 010.01 missing"
   [ -f "$SESSION_DIR/jobs/010.02-write-integration-tests.j.md" ] && echo "PASS: Child 010.02 exists" || echo "FAIL: Child 010.02 missing"
   ```

2. Attempt to complete parent with incomplete children
   ```bash
   ADVANCE_OUTPUT=$(ace-coworker report parent-report.md 2>&1)
   ADVANCE_EXIT=$?
   echo "Exit code: $ADVANCE_EXIT"
   echo "Output: $ADVANCE_OUTPUT"
   [ "$ADVANCE_EXIT" -ne 0 ] && echo "PASS: Non-zero exit code" || echo "FAIL: Expected non-zero exit code"
   echo "$ADVANCE_OUTPUT" | grep -qi "incomplete children" && echo "PASS: Error mentions 'incomplete children'" || echo "FAIL: Error should mention 'incomplete children'"
   echo "$ADVANCE_OUTPUT" | grep -q "010.01" && echo "PASS: Error lists child 010.01" || echo "FAIL: Error should list child 010.01"
   echo "$ADVANCE_OUTPUT" | grep -q "010.02" && echo "PASS: Error lists child 010.02" || echo "FAIL: Error should list child 010.02"
   ```

## Expected

- Exit code: non-zero (error)
- Error message contains "incomplete children"
- Error message lists incomplete child job numbers (010.01, 010.02)
