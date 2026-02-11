---
tc-id: TC-001
title: Hierarchy Auto-Completion
---

## Objective

Verify that ace-coworker correctly auto-completes parent jobs when all children finish, including multi-level cascade auto-completion (grandchild -> parent -> grandparent).

## Steps

### Phase 1: Single-Level Auto-Completion

1. Create session and add children under parent
   ```bash
   ace-coworker create job-single-level.yaml
   SESSION_DIR=$(find "$CACHE_BASE" -maxdepth 1 -mindepth 1 -type d | sort | tail -1)
   ace-coworker add child-one --after 010 --child -i "First child task"
   ace-coworker add child-two --after 010 --child -i "Second child task"
   [ -f "$SESSION_DIR/jobs/010.01-child-one.j.md" ] && echo "PASS: Child 010.01 exists" || echo "FAIL: Missing"
   [ -f "$SESSION_DIR/jobs/010.02-child-two.j.md" ] && echo "PASS: Child 010.02 exists" || echo "FAIL: Missing"
   ```

2. Verify parent cannot complete with incomplete children
   ```bash
   echo "# Attempting parent completion" > report.md
   PROTECT_OUTPUT=$(ace-coworker report report.md 2>&1)
   PROTECT_EXIT=$?
   [ "$PROTECT_EXIT" -ne 0 ] && echo "PASS: Parent completion blocked" || echo "FAIL: Parent should not complete"
   ```

3. Set parent pending, activate first child, and complete it
   ```bash
   sed -i.bak 's/status: in_progress/status: pending/' "$SESSION_DIR/jobs/010-parent-job.j.md"
   sed -i.bak 's/status: pending/status: in_progress/' "$SESSION_DIR/jobs/010.01-child-one.j.md"
   CHILD1_OUTPUT=$(ace-coworker report child1-report.md 2>&1)
   CHILD1_EXIT=$?
   [ "$CHILD1_EXIT" -eq 0 ] && echo "PASS: Child one completed" || echo "FAIL: Completion failed"
   ```

4. Verify child two is current and parent still pending
   ```bash
   STATUS_OUTPUT=$(ace-coworker status 2>&1)
   echo "$STATUS_OUTPUT" | grep -q "Current Step:.*child-two" && echo "PASS: Child two is current" || echo "FAIL: Should be current"
   grep -q "status: pending" "$SESSION_DIR/jobs/010-parent-job.j.md" && echo "PASS: Parent still pending" || echo "FAIL: Should be pending"
   ```

5. Complete second child and verify parent auto-completes
   ```bash
   CHILD2_OUTPUT=$(ace-coworker report child2-report.md 2>&1)
   CHILD2_EXIT=$?
   [ "$CHILD2_EXIT" -eq 0 ] && echo "PASS: Child two completed" || echo "FAIL: Completion failed"
   grep -q "status: done" "$SESSION_DIR/jobs/010-parent-job.j.md" && echo "PASS: Parent auto-completed" || echo "FAIL: Should auto-complete"
   [ -f "$SESSION_DIR/reports/010-parent-job.r.md" ] && echo "PASS: Auto-complete report created" || echo "FAIL: Report missing"
   grep -q "Auto-completed" "$SESSION_DIR/reports/010-parent-job.r.md" && echo "PASS: Report indicates auto-completion" || echo "FAIL: Should indicate auto-completion"
   STATUS_OUTPUT=$(ace-coworker status 2>&1)
   echo "$STATUS_OUTPUT" | grep -q "Current Step:.*final-step" && echo "PASS: Final step is current" || echo "FAIL: Should advance"
   ```

### Phase 2: Multi-Level Auto-Completion

6. Create new session with 3-level hierarchy
   ```bash
   rm -rf "$CACHE_BASE"/*
   ace-coworker create job-multi-level.yaml
   SESSION_DIR=$(find "$CACHE_BASE" -maxdepth 1 -mindepth 1 -type d | sort | tail -1)
   ace-coworker add parent --after 010 --child -i "Middle level job"
   [ -f "$SESSION_DIR/jobs/010.01-parent.j.md" ] && echo "PASS: Parent 010.01 created" || echo "FAIL: Missing"
   ace-coworker add child --after 010.01 --child -i "Bottom level job (grandchild)"
   [ -f "$SESSION_DIR/jobs/010.01.01-child.j.md" ] && echo "PASS: Grandchild 010.01.01 created" || echo "FAIL: Missing"
   ```

7. Activate grandchild and complete it to trigger cascade
   ```bash
   sed -i.bak 's/status: in_progress/status: pending/' "$SESSION_DIR/jobs/010-grandparent.j.md"
   sed -i.bak 's/status: in_progress/status: pending/' "$SESSION_DIR/jobs/010.01-parent.j.md"
   sed -i.bak 's/status: pending/status: in_progress/' "$SESSION_DIR/jobs/010.01.01-child.j.md"
   COMPLETE_OUTPUT=$(ace-coworker report grandchild-report.md 2>&1)
   COMPLETE_EXIT=$?
   [ "$COMPLETE_EXIT" -eq 0 ] && echo "PASS: Grandchild completed" || echo "FAIL: Completion failed"
   ```

8. Verify full chain auto-completed
   ```bash
   grep -q "status: done" "$SESSION_DIR/jobs/010.01.01-child.j.md" && echo "PASS: Grandchild done" || echo "FAIL: Not done"
   grep -q "status: done" "$SESSION_DIR/jobs/010.01-parent.j.md" && echo "PASS: Parent auto-completed" || echo "FAIL: Not auto-completed"
   [ -f "$SESSION_DIR/reports/010.01-parent.r.md" ] && echo "PASS: Parent report exists" || echo "FAIL: Missing"
   grep -q "status: done" "$SESSION_DIR/jobs/010-grandparent.j.md" && echo "PASS: Grandparent auto-completed" || echo "FAIL: Not auto-completed"
   [ -f "$SESSION_DIR/reports/010-grandparent.r.md" ] && echo "PASS: Grandparent report exists" || echo "FAIL: Missing"
   STATUS_OUTPUT=$(ace-coworker status 2>&1)
   echo "$STATUS_OUTPUT" | grep -q "Current Step:.*next-task" && echo "PASS: next-task is current" || echo "FAIL: Should be current"
   ```

## Expected

### Phase 1
- Parent 010 cannot complete while children incomplete
- After completing all children, parent auto-completes with "Auto-completed" report
- Workflow advances to next top-level job (020-final-step)

### Phase 2
- Completing grandchild (010.01.01) triggers cascade auto-completion
- Parent (010.01) auto-completes, grandparent (010) auto-completes
- Next top-level job (020-next-task) becomes in_progress
