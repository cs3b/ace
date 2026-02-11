---
tc-id: TC-002
title: Audit Trail Verification
---

## Objective

Verify that all audit trail metadata fields are present and correctly populated for child injection, sibling injection, renumbering, and dynamic adds.

## Steps

1. Create session and add child job
   ```bash
   ace-coworker create job-audit.yaml
   SESSION_DIR=$(find "$CACHE_BASE" -maxdepth 1 -mindepth 1 -type d | sort | tail -1)
   ace-coworker add child-task --after 010 --child -i "Child task"
   ```

2. Verify child_of audit trail
   ```bash
   grep -q 'added_by:.*child_of:010' "$SESSION_DIR/jobs/010.01-child-task.j.md" && echo "PASS: added_by: child_of:010 present" || echo "FAIL: Missing"
   grep -q 'parent:.*"010"' "$SESSION_DIR/jobs/010.01-child-task.j.md" && echo "PASS: parent: 010 present" || echo "FAIL: Missing"
   ```

3. Add another child and inject sibling to trigger renumbering
   ```bash
   ace-coworker add another-child --after 010 --child -i "Another child"
   ADD_OUTPUT=$(ace-coworker add injected-sibling --after 010.01 -i "Injected sibling" 2>&1)
   echo "$ADD_OUTPUT"
   ```

4. Verify injected_after and renumbering audit trails
   ```bash
   grep -q 'added_by:.*injected_after:010.01' "$SESSION_DIR/jobs/010.02-injected-sibling.j.md" && echo "PASS: injected_after audit present" || echo "FAIL: Missing"
   RENAMED_FILE=$(ls "$SESSION_DIR/jobs/"*another-child*.j.md 2>/dev/null | head -1)
   [ -n "$RENAMED_FILE" ] && echo "PASS: Renamed file found" || echo "FAIL: Not found"
   grep -q 'renumbered_from:' "$RENAMED_FILE" && echo "PASS: renumbered_from present" || echo "FAIL: Missing"
   grep -q 'renumbered_at:' "$RENAMED_FILE" && echo "PASS: renumbered_at present" || echo "FAIL: Missing"
   ```

5. Verify ISO8601 timestamp format
   ```bash
   TIMESTAMP=$(grep 'renumbered_at:' "$RENAMED_FILE" | sed 's/renumbered_at: *//')
   echo "Timestamp: $TIMESTAMP"
   echo "$TIMESTAMP" | grep -qE '^[0-9]{4}-[0-9]{2}-[0-9]{2}T' && echo "PASS: ISO8601 format" || echo "FAIL: Not ISO8601"
   ```

6. Add dynamic step and verify dynamic audit trail
   ```bash
   sed -i.bak 's/status: in_progress/status: done/' "$SESSION_DIR/jobs/010-initial-job.j.md"
   ADD_OUTPUT=$(ace-coworker add dynamic-step -i "Dynamically added" 2>&1)
   echo "$ADD_OUTPUT"
   DYNAMIC_FILE=$(ls "$SESSION_DIR/jobs/"*dynamic-step*.j.md 2>/dev/null | head -1)
   grep -q 'added_by:.*dynamic' "$DYNAMIC_FILE" && echo "PASS: added_by: dynamic present" || echo "FAIL: Missing"
   ```

## Expected

- Child jobs have `added_by: child_of:<parent>` and `parent: "<parent>"`
- Injected siblings have `added_by: injected_after:<number>`
- Renumbered jobs have `renumbered_from: <old_number>` and `renumbered_at: <ISO8601>`
- Dynamic jobs have `added_by: dynamic`
