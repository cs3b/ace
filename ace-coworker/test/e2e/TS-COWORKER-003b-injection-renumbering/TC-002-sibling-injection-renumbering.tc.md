---
tc-id: TC-002
title: Sibling Injection with Renumbering
---

## Objective

Verify that injecting a sibling after a child job correctly renumbers subsequent siblings.

## Steps

1. Inject sibling after 010.01 and verify renumbering
   ```bash
   ADD_OUTPUT=$(ace-coworker add run-linter --after 010.01 -i "Run linter checks" 2>&1)
   ADD_EXIT=$?
   [ "$ADD_EXIT" -eq 0 ] && echo "PASS: Exit code is 0" || echo "FAIL: Expected exit code 0"
   echo "$ADD_OUTPUT" | grep -q "Number: 010.02" && echo "PASS: New job is 010.02" || echo "FAIL: Expected job number 010.02"
   echo "$ADD_OUTPUT" | grep -q "sibling after 010.01" && echo "PASS: Relationship shows 'sibling after 010.01'" || echo "FAIL: Relationship should show sibling"
   echo "$ADD_OUTPUT" | grep -q "Renumbered jobs:" && echo "PASS: Renumbering announced" || echo "FAIL: Renumbering not shown"
   echo "$ADD_OUTPUT" | grep -q "010.02 -> 010.03" && echo "PASS: 010.02 shifted to 010.03" || echo "FAIL: Renumbering shift not shown"
   ```

2. Verify file state after renumbering
   ```bash
   [ -f "$SESSION_DIR/jobs/010.02-run-linter.j.md" ] && echo "PASS: 010.02-run-linter.j.md exists" || echo "FAIL: Missing"
   grep -q 'added_by:.*injected_after:010.01' "$SESSION_DIR/jobs/010.02-run-linter.j.md" && echo "PASS: added_by shows injected_after" || echo "FAIL: Incorrect added_by"
   [ -f "$SESSION_DIR/jobs/010.03-write-integration-tests.j.md" ] && echo "PASS: Old 010.02 is now 010.03" || echo "FAIL: Not found at 010.03"
   [ ! -f "$SESSION_DIR/jobs/010.02-write-integration-tests.j.md" ] && echo "PASS: Old 010.02-write-integration-tests gone" || echo "FAIL: Old file still exists"
   grep -q 'renumbered_from:.*010.02' "$SESSION_DIR/jobs/010.03-write-integration-tests.j.md" && echo "PASS: renumbered_from present" || echo "FAIL: Missing"
   grep -q 'renumbered_at:' "$SESSION_DIR/jobs/010.03-write-integration-tests.j.md" && echo "PASS: renumbered_at present" || echo "FAIL: Missing"
   ```

## Expected

- Sibling injected as 010.02, old 010.02 renumbered to 010.03
- Renumbered job has renumbered_from and renumbered_at metadata
