---
tc-id: TC-001
title: Child Phase Injection
---

## Objective

Verify that ace-assign correctly handles child injection via `add --after X --child`.

## Steps

1. Create assignment and add initial children
   ```bash
   ace-assign create job.yaml
   ASSIGNMENT_DIR=$(find "$CACHE_BASE" -maxdepth 1 -mindepth 1 -type d | sort | tail -1)
   ace-assign add write-unit-tests --after 010 --child -i "Write unit tests for the feature"
   ace-assign add write-integration-tests --after 010 --child -i "Write integration tests"
   [ -f "$ASSIGNMENT_DIR/phases/010.01-write-unit-tests.ph.md" ] && echo "PASS: Child 010.01 exists" || echo "FAIL: Child 010.01 missing"
   [ -f "$ASSIGNMENT_DIR/phases/010.02-write-integration-tests.ph.md" ] && echo "PASS: Child 010.02 exists" || echo "FAIL: Child 010.02 missing"
   ```

2. Add a third child and verify numbering and metadata
   ```bash
   ADD_OUTPUT=$(ace-assign add setup-fixtures --after 010 --child -i "Set up test fixtures" 2>&1)
   ADD_EXIT=$?
   [ "$ADD_EXIT" -eq 0 ] && echo "PASS: Exit code is 0" || echo "FAIL: Expected exit code 0"
   echo "$ADD_OUTPUT" | grep -q "010.03" && echo "PASS: New phase is 010.03" || echo "FAIL: Expected phase number 010.03"
   echo "$ADD_OUTPUT" | grep -q "child of 010" && echo "PASS: Relationship shows 'child of 010'" || echo "FAIL: Relationship should show 'child of 010'"
   [ -f "$ASSIGNMENT_DIR/phases/010.03-setup-fixtures.ph.md" ] && echo "PASS: Phase file created" || echo "FAIL: Phase file not created"
   grep -q 'parent:.*"010"' "$ASSIGNMENT_DIR/phases/010.03-setup-fixtures.ph.md" && echo "PASS: Has parent: 010" || echo "FAIL: Missing parent field"
   grep -q 'added_by:.*child_of:010' "$ASSIGNMENT_DIR/phases/010.03-setup-fixtures.ph.md" && echo "PASS: added_by shows child_of:010" || echo "FAIL: added_by missing"
   ```

## Expected

- Child phase created as 010.03 with parent: "010" and added_by: child_of:010
- Three children exist: 010.01, 010.02, 010.03
