---
tc-id: TC-001
title: Error - Advance Parent with Incomplete Children
---

## Objective

Verify that attempting to complete a parent phase while children are incomplete fails with a clear error listing the incomplete children.

## Steps

1. Create assignment and add children under phase 010
   ```bash
   ace-assign create job.yaml
   ASSIGNMENT_DIR=$(find "$CACHE_BASE" -maxdepth 1 -mindepth 1 -type d | sort | tail -1)
   ace-assign add write-unit-tests --after 010 --child -i "Write unit tests for the feature"
   ace-assign add write-integration-tests --after 010 --child -i "Write integration tests"
   [ -f "$ASSIGNMENT_DIR/phases/010.01-write-unit-tests.ph.md" ] && echo "PASS: Child 010.01 exists" || echo "FAIL: Child 010.01 missing"
   [ -f "$ASSIGNMENT_DIR/phases/010.02-write-integration-tests.ph.md" ] && echo "PASS: Child 010.02 exists" || echo "FAIL: Child 010.02 missing"
   ```

2. Attempt to complete parent with incomplete children
   ```bash
   ADVANCE_OUTPUT=$(ace-assign report parent-report.md 2>&1)
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
- Error message lists incomplete child phase numbers (010.01, 010.02)
