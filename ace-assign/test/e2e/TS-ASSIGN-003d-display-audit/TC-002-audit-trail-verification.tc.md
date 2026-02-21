---
tc-id: TC-002
title: Audit Trail Verification
---

## Objective

Verify that all audit trail metadata fields are present and correctly populated for child injection, sibling injection, renumbering, and dynamic adds.

## Steps

1. Create assignment and add child phase
   ```bash
   ace-assign create job-audit.yaml
   ASSIGNMENT_DIR=$(find "$CACHE_BASE" -maxdepth 1 -mindepth 1 -type d | sort | tail -1)
   ace-assign add child-task --after 010 --child -i "Child task"
   ```

2. Verify child_of audit trail
   ```bash
   grep -q 'added_by:.*child_of:010' "$ASSIGNMENT_DIR/phases/010.01-child-task.ph.md" && echo "PASS: added_by: child_of:010 present" || echo "FAIL: Missing"
   grep -qE "parent:.*['\"]010['\"]" "$ASSIGNMENT_DIR/phases/010.01-child-task.ph.md" && echo "PASS: parent: 010 present" || echo "FAIL: Missing"
   ```

3. Add another child and inject sibling to trigger renumbering
   ```bash
   ace-assign add another-child --after 010 --child -i "Another child"
   ADD_OUTPUT=$(ace-assign add injected-sibling --after 010.01 -i "Injected sibling" 2>&1)
   echo "$ADD_OUTPUT"
   ```

4. Verify injected_after and renumbering audit trails
   ```bash
   grep -q 'added_by:.*injected_after:010.01' "$ASSIGNMENT_DIR/phases/010.02-injected-sibling.ph.md" && echo "PASS: injected_after audit present" || echo "FAIL: Missing"
   RENAMED_FILE=$(ls "$ASSIGNMENT_DIR/phases/"*another-child*.ph.md 2>/dev/null | head -1)
   [ -n "$RENAMED_FILE" ] && echo "PASS: Renamed file found" || echo "FAIL: Not found"
   grep -q 'renumbered_from:' "$RENAMED_FILE" && echo "PASS: renumbered_from present" || echo "FAIL: Missing"
   grep -q 'renumbered_at:' "$RENAMED_FILE" && echo "PASS: renumbered_at present" || echo "FAIL: Missing"
   ```

5. Verify ISO8601 timestamp format
   ```bash
   TIMESTAMP=$(grep 'renumbered_at:' "$RENAMED_FILE" | sed 's/renumbered_at: *//')
   echo "Timestamp: $TIMESTAMP"
   echo "$TIMESTAMP" | grep -qE "^['\"]?[0-9]{4}-[0-9]{2}-[0-9]{2}T" && echo "PASS: ISO8601 format" || echo "FAIL: Not ISO8601"
   ```

6. Add dynamic phase and verify dynamic audit trail
   ```bash
   sed -i.bak 's/status: in_progress/status: done/' "$ASSIGNMENT_DIR/phases/010-initial-job.ph.md"
   ADD_OUTPUT=$(ace-assign add dynamic-step -i "Dynamically added" 2>&1)
   echo "$ADD_OUTPUT"
   DYNAMIC_FILE=$(ls "$ASSIGNMENT_DIR/phases/"*dynamic-step*.ph.md 2>/dev/null | head -1)
   grep -q 'added_by:.*dynamic' "$DYNAMIC_FILE" && echo "PASS: added_by: dynamic present" || echo "FAIL: Missing"
   ```

## Expected

- Child phases have `added_by: child_of:<parent>` and `parent: "<parent>"`
- Injected siblings have `added_by: injected_after:<number>`
- Renumbered phases have `renumbered_from: <old_number>` and `renumbered_at: <ISO8601>`
- Dynamic phases have `added_by: dynamic`
