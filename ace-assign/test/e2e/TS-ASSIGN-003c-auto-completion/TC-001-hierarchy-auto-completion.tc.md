---
tc-id: TC-001
title: Hierarchy Auto-Completion
---

## Objective

Verify that ace-assign correctly auto-completes parent phases when all children finish, including multi-level cascade auto-completion (grandchild -> parent -> grandparent).

## Steps

### Phase 1: Single-Level Auto-Completion

1. Create assignment and add children under parent
   ```bash
   ace-assign create job-single-level.yaml
   ASSIGNMENT_DIR=$(find "$CACHE_BASE" -maxdepth 1 -mindepth 1 -type d | sort | tail -1)
   ace-assign add child-one --after 010 --child -i "First child task"
   ace-assign add child-two --after 010 --child -i "Second child task"
   [ -f "$ASSIGNMENT_DIR/phases/010.01-child-one.ph.md" ] && echo "PASS: Child 010.01 exists" || echo "FAIL: Missing"
   [ -f "$ASSIGNMENT_DIR/phases/010.02-child-two.ph.md" ] && echo "PASS: Child 010.02 exists" || echo "FAIL: Missing"
   ```

2. Verify parent cannot complete with incomplete children
   ```bash
   echo "# Attempting parent completion" > report.md
   PROTECT_OUTPUT=$(ace-assign report report.md 2>&1)
   PROTECT_EXIT=$?
   [ "$PROTECT_EXIT" -ne 0 ] && echo "PASS: Parent completion blocked" || echo "FAIL: Parent should not complete"
   ```

3. Set parent pending, activate first child, and complete it
   ```bash
   ASSIGNMENT_DIR=$(find "$CACHE_BASE" -maxdepth 1 -mindepth 1 -type d | sort | tail -1)
   sed -i.bak 's/status: in_progress/status: pending/' "$ASSIGNMENT_DIR/phases/010-parent-job.ph.md"
   sed -i.bak 's/status: pending/status: in_progress/' "$ASSIGNMENT_DIR/phases/010.01-child-one.ph.md"
   CHILD1_OUTPUT=$(ace-assign report child1-report.md 2>&1)
   CHILD1_EXIT=$?
   [ "$CHILD1_EXIT" -eq 0 ] && echo "PASS: Child one completed" || echo "FAIL: Completion failed"
   ```

4. Verify child two is current and parent still pending
   ```bash
   ASSIGNMENT_DIR=$(find "$CACHE_BASE" -maxdepth 1 -mindepth 1 -type d | sort | tail -1)
   STATUS_OUTPUT=$(ace-assign status 2>&1)
   echo "$STATUS_OUTPUT" | grep -q "Current Phase:.*child-two" && echo "PASS: Child two is current" || echo "FAIL: Should be current"
   grep -q "status: pending" "$ASSIGNMENT_DIR/phases/010-parent-job.ph.md" && echo "PASS: Parent still pending" || echo "FAIL: Should be pending"
   ```

5. Complete second child and verify parent auto-completes
   ```bash
   ASSIGNMENT_DIR=$(find "$CACHE_BASE" -maxdepth 1 -mindepth 1 -type d | sort | tail -1)
   CHILD2_OUTPUT=$(ace-assign report child2-report.md 2>&1)
   CHILD2_EXIT=$?
   [ "$CHILD2_EXIT" -eq 0 ] && echo "PASS: Child two completed" || echo "FAIL: Completion failed"
   grep -q "status: done" "$ASSIGNMENT_DIR/phases/010-parent-job.ph.md" && echo "PASS: Parent auto-completed" || echo "FAIL: Should auto-complete"
   [ -f "$ASSIGNMENT_DIR/reports/010-parent-job.r.md" ] && echo "PASS: Auto-complete report created" || echo "FAIL: Report missing"
   grep -q "Auto-completed" "$ASSIGNMENT_DIR/reports/010-parent-job.r.md" && echo "PASS: Report indicates auto-completion" || echo "FAIL: Should indicate auto-completion"
   STATUS_OUTPUT=$(ace-assign status 2>&1)
   echo "$STATUS_OUTPUT" | grep -q "Current Phase:.*final-step" && echo "PASS: Final phase is current" || echo "FAIL: Should advance"
   ```

### Phase 2: Multi-Level Auto-Completion

6. Create new assignment with 3-level hierarchy
   ```bash
   rm -rf "$CACHE_BASE"/*
   ace-assign create job-multi-level.yaml
   ASSIGNMENT_DIR=$(find "$CACHE_BASE" -maxdepth 1 -mindepth 1 -type d | sort | tail -1)
   ace-assign add parent --after 010 --child -i "Middle level phase"
   [ -f "$ASSIGNMENT_DIR/phases/010.01-parent.ph.md" ] && echo "PASS: Parent 010.01 created" || echo "FAIL: Missing"
   ace-assign add child --after 010.01 --child -i "Bottom level phase (grandchild)"
   [ -f "$ASSIGNMENT_DIR/phases/010.01.01-child.ph.md" ] && echo "PASS: Grandchild 010.01.01 created" || echo "FAIL: Missing"
   ```

7. Activate grandchild and complete it to trigger cascade
   ```bash
   ASSIGNMENT_DIR=$(find "$CACHE_BASE" -maxdepth 1 -mindepth 1 -type d | sort | tail -1)
   sed -i.bak 's/status: in_progress/status: pending/' "$ASSIGNMENT_DIR/phases/010-grandparent.ph.md"
   sed -i.bak 's/status: in_progress/status: pending/' "$ASSIGNMENT_DIR/phases/010.01-parent.ph.md"
   sed -i.bak 's/status: pending/status: in_progress/' "$ASSIGNMENT_DIR/phases/010.01.01-child.ph.md"
   COMPLETE_OUTPUT=$(ace-assign report grandchild-report.md 2>&1)
   COMPLETE_EXIT=$?
   [ "$COMPLETE_EXIT" -eq 0 ] && echo "PASS: Grandchild completed" || echo "FAIL: Completion failed"
   ```

8. Verify full chain auto-completed
   ```bash
   ASSIGNMENT_DIR=$(find "$CACHE_BASE" -maxdepth 1 -mindepth 1 -type d | sort | tail -1)
   grep -q "status: done" "$ASSIGNMENT_DIR/phases/010.01.01-child.ph.md" && echo "PASS: Grandchild done" || echo "FAIL: Not done"
   grep -q "status: done" "$ASSIGNMENT_DIR/phases/010.01-parent.ph.md" && echo "PASS: Parent auto-completed" || echo "FAIL: Not auto-completed"
   [ -f "$ASSIGNMENT_DIR/reports/010.01-parent.r.md" ] && echo "PASS: Parent report exists" || echo "FAIL: Missing"
   grep -q "status: done" "$ASSIGNMENT_DIR/phases/010-grandparent.ph.md" && echo "PASS: Grandparent auto-completed" || echo "FAIL: Not auto-completed"
   [ -f "$ASSIGNMENT_DIR/reports/010-grandparent.r.md" ] && echo "PASS: Grandparent report exists" || echo "FAIL: Missing"
   STATUS_OUTPUT=$(ace-assign status 2>&1)
   echo "$STATUS_OUTPUT" | grep -q "Current Phase:.*next-task" && echo "PASS: next-task is current" || echo "FAIL: Should be current"
   ```

## Expected

### Phase 1
- Parent 010 cannot complete while children incomplete
- After completing all children, parent auto-completes with "Auto-completed" report
- Workflow advances to next top-level phase (020-final-step)

### Phase 2
- Completing grandchild (010.01.01) triggers cascade auto-completion
- Parent (010.01) auto-completes, grandparent (010) auto-completes
- Next top-level phase (020-next-task) becomes in_progress
