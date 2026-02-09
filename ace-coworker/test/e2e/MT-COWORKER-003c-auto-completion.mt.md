---
test-id: MT-COWORKER-003c
title: Hierarchical Jobs - Auto-Completion
area: coworker
package: ace-coworker
priority: high
duration: ~3min
automation-candidate: true
requires:
  tools: [ace-coworker]
  ruby: ">= 3.0"
last-verified: 2026-02-08
verified-by: claude-opus-4-6
---

# Hierarchical Jobs - Auto-Completion

## Objective

Verify that ace-coworker correctly auto-completes parent jobs when all children finish, including multi-level cascade auto-completion (grandchild -> parent -> grandparent).

## Prerequisites

- Ruby >= 3.0 installed
- ace-coworker package available (via bundle exec or installed)

## Environment Setup

```bash
```

## Test Cases

### TC-006: Complete All Children - Parent Auto-Completes

**Objective:** Verify that a parent job auto-completes when all its children are done.

**Steps:**
1. Create session with two top-level steps and add children
   ```bash
   ace-test-e2e-sh "$TEST_DIR" bash << 'SANDBOX'
   cat > "job2.yaml" << 'EOF'
name: auto-complete-test
description: Test auto-completion of parent jobs

steps:
  - name: parent-job
    instructions: This parent should auto-complete when children finish

  - name: final-step
    instructions: Final step after parent completes
EOF

   CREATE_OUTPUT=$($ACE_COWORKER create "job2.yaml" 2>&1)
   CREATE_EXIT=$?
   [ "$CREATE_EXIT" -eq 0 ] && echo "PASS: Session created" || echo "FAIL: Session creation failed"
   SESSION_DIR=$(find "$CACHE_BASE" -maxdepth 1 -mindepth 1 -type d 2>/dev/null | sort | tail -1)

   $ACE_COWORKER add child-one --after 010 --child -i "First child task" > /dev/null 2>&1
   $ACE_COWORKER add child-two --after 010 --child -i "Second child task" > /dev/null 2>&1

   [ -f "$SESSION_DIR/jobs/010.01-child-one.j.md" ] && echo "PASS: Child 010.01 exists" || echo "FAIL: Child 010.01 missing"
   [ -f "$SESSION_DIR/jobs/010.02-child-two.j.md" ] && echo "PASS: Child 010.02 exists" || echo "FAIL: Child 010.02 missing"
   SANDBOX
   ```

2. Verify parent cannot complete with incomplete children
   ```bash
   ace-test-e2e-sh "$TEST_DIR" bash << 'SANDBOX'
   echo "# Attempting parent completion" > "report.md"
   PROTECT_OUTPUT=$($ACE_COWORKER report "report.md" 2>&1)
   PROTECT_EXIT=$?
   echo "$PROTECT_OUTPUT"
   [ "$PROTECT_EXIT" -ne 0 ] && echo "PASS: Parent completion blocked" || echo "FAIL: Parent should not complete"
   SANDBOX
   ```

3. Set parent pending, mark first child in_progress, and complete it
   ```bash
   ace-test-e2e-sh "$TEST_DIR" bash << 'SANDBOX'
   sed -i.bak 's/status: in_progress/status: pending/' "$SESSION_DIR/jobs/010-parent-job.j.md"
   sed -i.bak 's/status: pending/status: in_progress/' "$SESSION_DIR/jobs/010.01-child-one.j.md"

   cat > "child1-report.md" << 'EOF'
# Child One Report

First child completed successfully.
EOF
   CHILD1_OUTPUT=$($ACE_COWORKER report "child1-report.md" 2>&1)
   CHILD1_EXIT=$?
   echo "Exit code: $CHILD1_EXIT"
   [ "$CHILD1_EXIT" -eq 0 ] && echo "PASS: Child one completed" || echo "FAIL: Child one completion failed"
   SANDBOX
   ```

4. Verify child two is now current and parent still pending
   ```bash
   ace-test-e2e-sh "$TEST_DIR" bash << 'SANDBOX'
   STATUS_OUTPUT=$($ACE_COWORKER status 2>&1)
   echo "$STATUS_OUTPUT"
   echo "$STATUS_OUTPUT" | grep -q "Current Step:.*child-two" && echo "PASS: Child two is now current" || echo "FAIL: Child two should be current"
   grep -q "status: pending" "$SESSION_DIR/jobs/010-parent-job.j.md" && echo "PASS: Parent still pending" || echo "FAIL: Parent should still be pending"
   SANDBOX
   ```

5. Complete second child and verify parent auto-completes
   ```bash
   ace-test-e2e-sh "$TEST_DIR" bash << 'SANDBOX'
   cat > "child2-report.md" << 'EOF'
# Child Two Report

Second child completed successfully.
EOF
   CHILD2_OUTPUT=$($ACE_COWORKER report "child2-report.md" 2>&1)
   CHILD2_EXIT=$?
   [ "$CHILD2_EXIT" -eq 0 ] && echo "PASS: Child two completed" || echo "FAIL: Child two completion failed"

   grep -q "status: done" "$SESSION_DIR/jobs/010-parent-job.j.md" && echo "PASS: Parent auto-completed" || echo "FAIL: Parent should auto-complete"
   SANDBOX
   ```

6. Verify auto-complete report and final-step is now current
   ```bash
   ace-test-e2e-sh "$TEST_DIR" bash << 'SANDBOX'
   [ -f "$SESSION_DIR/reports/010-parent-job.r.md" ] && echo "PASS: Auto-complete report created" || echo "FAIL: Auto-complete report missing"
   grep -q "Auto-completed" "$SESSION_DIR/reports/010-parent-job.r.md" && echo "PASS: Report indicates auto-completion" || echo "FAIL: Report should indicate auto-completion"

   STATUS_OUTPUT=$($ACE_COWORKER status 2>&1)
   echo "$STATUS_OUTPUT"
   echo "$STATUS_OUTPUT" | grep -q "Current Step:.*final-step" && echo "PASS: Final step is now current" || echo "FAIL: Final step should be current"
   SANDBOX
   ```

**Expected:**
- Parent 010 cannot complete while children incomplete
- After completing all children, parent auto-completes
- Auto-completion creates report with "Auto-completed" message
- Workflow advances to next top-level job (020)

**Actual:** [Record during execution]

**Status:** [ ] Pass / [ ] Fail

---

### TC-007: Multi-Level Auto-Completion (Grandparent Chain)

**Objective:** Verify that auto-completion cascades up multiple levels (grandchild -> parent -> grandparent).

**Steps:**
1. Create session and build 3-level hierarchy
   ```bash
   ace-test-e2e-sh "$TEST_DIR" bash << 'SANDBOX'
   cat > "job3.yaml" << 'EOF'
name: multi-level-test
description: Test multi-level auto-completion

steps:
  - name: grandparent
    instructions: Top level job

  - name: next-task
    instructions: Should become current after auto-completion chain
EOF

   CREATE_OUTPUT=$($ACE_COWORKER create "job3.yaml" 2>&1)
   [ "$?" -eq 0 ] && echo "PASS: Session created" || echo "FAIL: Session creation failed"
   SESSION_DIR=$(find "$CACHE_BASE" -maxdepth 1 -mindepth 1 -type d 2>/dev/null | sort | tail -1)

   $ACE_COWORKER add parent --after 010 --child -i "Middle level job" > /dev/null 2>&1
   [ -f "$SESSION_DIR/jobs/010.01-parent.j.md" ] && echo "PASS: Parent 010.01 created" || echo "FAIL: Parent creation failed"

   $ACE_COWORKER add child --after 010.01 --child -i "Bottom level job (grandchild)" > /dev/null 2>&1
   [ -f "$SESSION_DIR/jobs/010.01.01-child.j.md" ] && echo "PASS: Grandchild 010.01.01 created" || echo "FAIL: Grandchild creation failed"
   SANDBOX
   ```

2. Set grandchild as in_progress and verify state
   ```bash
   ace-test-e2e-sh "$TEST_DIR" bash << 'SANDBOX'
   sed -i.bak 's/status: in_progress/status: pending/' "$SESSION_DIR/jobs/010-grandparent.j.md"
   sed -i.bak 's/status: pending/status: in_progress/' "$SESSION_DIR/jobs/010.01.01-child.j.md"

   STATUS_OUTPUT=$($ACE_COWORKER status 2>&1)
   echo "$STATUS_OUTPUT"
   echo "$STATUS_OUTPUT" | grep -q "Current Step:.*child" && echo "PASS: Grandchild is current" || echo "FAIL: Grandchild should be current"
   SANDBOX
   ```

3. Complete grandchild to trigger chain auto-completion
   ```bash
   ace-test-e2e-sh "$TEST_DIR" bash << 'SANDBOX'
   cat > "grandchild-report.md" << 'EOF'
# Grandchild Report

Grandchild completed - should trigger chain auto-completion.
EOF
   COMPLETE_OUTPUT=$($ACE_COWORKER report "grandchild-report.md" 2>&1)
   COMPLETE_EXIT=$?
   echo "Exit code: $COMPLETE_EXIT"
   echo "Output:"
   echo "$COMPLETE_OUTPUT"
   [ "$COMPLETE_EXIT" -eq 0 ] && echo "PASS: Grandchild completed" || echo "FAIL: Grandchild completion failed"
   SANDBOX
   ```

4. Verify full chain auto-completed and next-task is now current
   ```bash
   ace-test-e2e-sh "$TEST_DIR" bash << 'SANDBOX'
   grep -q "status: done" "$SESSION_DIR/jobs/010.01.01-child.j.md" && echo "PASS: Grandchild is done" || echo "FAIL: Grandchild should be done"
   grep -q "status: done" "$SESSION_DIR/jobs/010.01-parent.j.md" && echo "PASS: Parent auto-completed" || echo "FAIL: Parent should auto-complete"
   [ -f "$SESSION_DIR/reports/010.01-parent.r.md" ] && echo "PASS: Parent auto-complete report exists" || echo "FAIL: Parent report missing"
   grep -q "status: done" "$SESSION_DIR/jobs/010-grandparent.j.md" && echo "PASS: Grandparent auto-completed" || echo "FAIL: Grandparent should auto-complete"
   [ -f "$SESSION_DIR/reports/010-grandparent.r.md" ] && echo "PASS: Grandparent auto-complete report exists" || echo "FAIL: Grandparent report missing"

   STATUS_OUTPUT=$($ACE_COWORKER status 2>&1)
   echo "$STATUS_OUTPUT"
   echo "$STATUS_OUTPUT" | grep -q "Current Step:.*next-task" && echo "PASS: next-task is now current" || echo "FAIL: next-task should be current"
   grep -q "status: in_progress" "$SESSION_DIR/jobs/020-next-task.j.md" && echo "PASS: 020 is in_progress" || echo "FAIL: 020 should be in_progress"
   SANDBOX
   ```

**Expected:**
- Completing grandchild (010.01.01) triggers cascade:
  - Parent (010.01) auto-completes (all children done)
  - Grandparent (010) auto-completes (all children done)
- Next top-level job (020) becomes in_progress

**Actual:** [Record during execution]

**Status:** [ ] Pass / [ ] Fail

---

## Cleanup

```bash
cd "$PROJECT_ROOT"
rm -rf "$TEST_DIR"
find "$CACHE_BASE" -maxdepth 1 -mindepth 1 -type d -exec rm -rf {} + 2>/dev/null || true
echo "Cleanup complete"
```

## Success Criteria

- [ ] TC-006: Parent auto-completes when all children finish
- [ ] TC-007: Multi-level auto-completion cascades (grandchild -> parent -> grandparent)
