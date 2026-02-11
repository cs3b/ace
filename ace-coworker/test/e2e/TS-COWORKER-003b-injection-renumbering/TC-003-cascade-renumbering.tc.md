---
tc-id: TC-003
title: Cascade Renumbering of Descendants
---

## Objective

Verify that when a parent job is renumbered, its descendant jobs are also cascade-renumbered.

## Steps

1. Add grandchild under 010.03 and inject sibling to trigger cascade
   ```bash
   ace-coworker add integration-db-tests --after 010.03 --child -i "Database integration tests"
   [ -f "$SESSION_DIR/jobs/010.03.01-integration-db-tests.j.md" ] && echo "PASS: 010.03.01 created" || echo "FAIL: Not created"
   ADD_OUTPUT=$(ace-coworker add static-analysis --after 010.02 -i "Run static analysis" 2>&1)
   ADD_EXIT=$?
   [ "$ADD_EXIT" -eq 0 ] && echo "PASS: Exit code is 0" || echo "FAIL: Expected exit code 0"
   echo "$ADD_OUTPUT" | grep -q "010.03 -> 010.04" && echo "PASS: Parent shifted to 010.04" || echo "FAIL: Parent shift not shown"
   ```

2. Verify cascade renumbering of child
   ```bash
   [ -f "$SESSION_DIR/jobs/010.03-static-analysis.j.md" ] && echo "PASS: New 010.03 exists" || echo "FAIL: Missing"
   [ -f "$SESSION_DIR/jobs/010.04-write-integration-tests.j.md" ] && echo "PASS: Old 010.03 is now 010.04" || echo "FAIL: Not at 010.04"
   [ -f "$SESSION_DIR/jobs/010.04.01-integration-db-tests.j.md" ] && echo "PASS: Child cascaded to 010.04.01" || echo "FAIL: Child not cascaded"
   [ ! -f "$SESSION_DIR/jobs/010.03.01-integration-db-tests.j.md" ] && echo "PASS: Old 010.03.01 gone" || echo "FAIL: Old child still exists"
   grep -q 'renumbered_from:.*010.03.01' "$SESSION_DIR/jobs/010.04.01-integration-db-tests.j.md" && echo "PASS: Child has renumbered_from" || echo "FAIL: Missing"
   ```

## Expected

- Cascade renumbering: parent 010.03 -> 010.04, child 010.03.01 -> 010.04.01
- All shifted jobs have renumbered_from metadata
