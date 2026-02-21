---
tc-id: TC-003
title: Cascade Renumbering of Descendant Phases
---

## Objective

Verify that when a parent phase is renumbered, its descendant phases are also cascade-renumbered.

## Steps

1. Add grandchild under 010.03 and inject sibling to trigger cascade
   ```bash
   ASSIGNMENT_DIR=$(find "$CACHE_BASE" -maxdepth 1 -mindepth 1 -type d | sort | tail -1)
   ace-assign add integration-db-tests --after 010.03 --child -i "Database integration tests"
   [ -f "$ASSIGNMENT_DIR/phases/010.03.01-integration-db-tests.ph.md" ] && echo "PASS: 010.03.01 created" || echo "FAIL: Not created"
   ADD_OUTPUT=$(ace-assign add static-analysis --after 010.02 -i "Run static analysis" 2>&1)
   ADD_EXIT=$?
   [ "$ADD_EXIT" -eq 0 ] && echo "PASS: Exit code is 0" || echo "FAIL: Expected exit code 0"
   echo "$ADD_OUTPUT" | grep -q "010.03 -> 010.04" && echo "PASS: Parent shifted to 010.04" || echo "FAIL: Parent shift not shown"
   ```

2. Verify cascade renumbering of child
   ```bash
   ASSIGNMENT_DIR=$(find "$CACHE_BASE" -maxdepth 1 -mindepth 1 -type d | sort | tail -1)
   [ -f "$ASSIGNMENT_DIR/phases/010.03-static-analysis.ph.md" ] && echo "PASS: New 010.03 exists" || echo "FAIL: Missing"
   [ -f "$ASSIGNMENT_DIR/phases/010.04-write-integration-tests.ph.md" ] && echo "PASS: Old 010.03 is now 010.04" || echo "FAIL: Not at 010.04"
   [ -f "$ASSIGNMENT_DIR/phases/010.04.01-integration-db-tests.ph.md" ] && echo "PASS: Child cascaded to 010.04.01" || echo "FAIL: Child not cascaded"
   [ ! -f "$ASSIGNMENT_DIR/phases/010.03.01-integration-db-tests.ph.md" ] && echo "PASS: Old 010.03.01 gone" || echo "FAIL: Old child still exists"
   grep -q 'renumbered_from:.*010.03.01' "$ASSIGNMENT_DIR/phases/010.04.01-integration-db-tests.ph.md" && echo "PASS: Child has renumbered_from" || echo "FAIL: Missing"
   ```

## Expected

- Cascade renumbering: parent 010.03 -> 010.04, child 010.03.01 -> 010.04.01
- All shifted phases have renumbered_from metadata
